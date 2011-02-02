module Reak
  module Parser
    class Newspeak < Squeak
      class NewspeakTransformer < Transformer
        def self.arglist(list)
          list ? list.map { |l| l[:var] } : []
        end

        rule :var => simple(:name) do
          name
        end

        rule :expr => "" do
          Reak::Syntax::NilKind.new
        end

        rule :integer => {:radix => simple(:radix), :value => simple(:value)} do
          Reak::Syntax::Integer.new(value, radix)
        end

        rule :symbol => simple(:value) do
          Reak::Syntax::Symbol.new(value)
        end

        rule :symbol => subtree(:values) do
          Reak::Syntax::Symbol.new values.map { |v| v[:keyword] }.join
        end

        rule :character => simple(:character) do
          Reak::Syntax::Character.new(character)
        end

        rule :string => simple(:value) do
          Reak::Syntax::String.new value.gsub("''", "'")
        end

        rule :float => { :power => simple(:power), :base => simple(:base) } do
          Reak::Syntax::Float.new(base.to_f ** power.to_i)
        end

        rule :array => sequence(:values) do
          Reak::Syntax::Array.new values
        end

        rule :array => simple(:values) do
          Reak::Syntax::Array.new [values]
        end

        rule :expr => sequence(:ast) do
          Reak::Syntax::Expression.new(ast)
        end

        rule :expr => simple(:ast) do
          next if ast.respond_to? :to_str and ast =~ /^\s$/
          Reak::Syntax::Expression.new([ast])
        end

        rule :expr => { :return => simple(:expr) } do
          Reak::Syntax::ReturnValue.new expr
        end

        rule :entry => simple(:entry) do
          entry
        end

        rule :scaled_decimal => { :mantissa => { :minor => simple(:minor), :major=> simple(:major) }, :digits => simple(:digits) } do
          Reak::Syntax::ScaledDecimal.new major, minor, digits
        end

        rule :scaled_decimal => { :mantissa => { :major => simple(:major) }, :digits => simple(:digits) } do
          Reak::Syntax::ScaledDecimal.new major, "", digits
        end

        rule :reserved => "true" do
          Reak::Syntax::TrueKind.new
        end

        rule :reserved => "false" do
          Reak::Syntax::FalseKind.new
        end

        rule :reserved => "nil" do
          Reak::Syntax::NilKind.new
        end

        rule :reserved => "self" do
          Reak::Syntax::Self.new
        end

        rule :reserved => "super" do
          Reak::Syntax::Super.new
        end

        rule :locals => subtree(:locals), :code => simple(:code) do
          Reak::Syntax::Body.new Transformer.arglist(locals), code
        end

        rule :closure => { :args => subtree(:args), :body => simple(:body) } do
          Reak::Syntax::Closure.new Transformer.arglist(args), body
        end

        rule :call => { :type => :unary, :send => { :selector => simple(:selector) }} do
          Reak::Syntax::Message.new selector
        end

        rule :call => { :type => :binary, :send => { :selector => simple(:selector), :value => simple(:arg) }} do
          Reak::Syntax::Message.new selector, arg
        end

        rule :call => { :type => :chain, :send => sequence(:messages), :on => simple(:on) } do
          messages.inject(on) { |o,m| Reak::Syntax::Call.new(o,m) }
        end

        rule :keyword => simple(:key), :value => simple(:value) do
          Reak::Syntax::MessageKey.new key, value
        end

        rule :call => { :type => :keyword, :send => sequence(:keys) } do
          message = Reak::Syntax::Message.new ""
          keys.each do |key|
            message.selector << key.key
            message.args << key.arg
          end
          message
        end

        rule :call => { :type => :direct, :send => simple(:message), :on => simple(:on) } do
          Reak::Syntax::Call.new on, message
        end

        rule :call => { :type => :unbalanced_cascade, :send => sequence(:cascade), :on => simple(:first) } do
          Reak::Syntax::Cascade.new first.reciever, [first.message] + cascade
        end

        rule :assign => { :target => simple(:var), :value => simple(:value) } do
          Reak::Syntax::Assign.new var, value
        end

        rule :keyword => simple(:key), :var => simple(:param) do
          Reak::Syntax::MessageKey.new key, param
        end

        rule :superclass => simple(:sc), :locals => simple(:slots), :class_name => simple(:name),
                                    :primary_factory => sequence(:keys), :code => simple(:block) do
          klass = Reak::Syntax::ClassHeader.new(name, sc, slots)
          message = Reak::Syntax::Message.new ""
          keys.each do |key|
            message.selector << key.key
            message.args << key.arg
          end
          message
          klass.primary_factory = { message => block }
          klass
        end

        rule :keyword => simple(:kw), :locals => simple(:vars), :var => simple(:param), :code => simple(:block) do
          Reak::Syntax::Method.new(kw, param, vars, block)
        end

        rule :name => simple(:category_name), :methods => sequence(:ms) do
          Reak::Syntax::Category.new(category_name, ms)
        end

        rule :categories => sequence(:cats), :nested_classes => sequence(:nets) do
          Reak::Syntax::ClassBody.new(cats, nets)
        end

        rule :categories => sequence(:cats), :nested_classes => simple(:nets) do
          Reak::Syntax::ClassBody.new(cats, nets)
        end

        rule :categories => simple(:cats), :nested_classes => sequence(:nets) do
          Reak::Syntax::ClassBody.new(cats, nets)
        end

        rule :class_category => simple(:pkg), :class_body => simple(:body), :class_header => simple(:header) do
          Reak::Syntax::Class.new(pkg, header, body)
        end
      end

      FormatVersion = "Newsqueak2"

      class ::File
        alias :"old_push" :"<<"
        def << str
          old_push(str)
          old_push("\n")
        end
      end

      def initialize
        super
        @transformer = NewspeakTransformer.new
      end

      def compile(code)
        result = file_out.parse(code)
        compileClass(result)
      end

      def compile_class(klass)
        package = "#{klass.category}/#{klass.name}"

        FileUtils.mkdir_p(package)
        file = File.open("#{package}/#{klass.name}.java", 'w')
        file << "package #{package.gsub("/", ".")};" <<
          "public class #{klass.name} extends NewspeakObject {" <<
          "public #{klass.name}(NewspeakClass klass) { super(klass); }" <<
            "// TODO: instance methods" <<
          "}"
        file.close

        file = File.open("#{package}/#{klass.name}Class.java", 'w')
        primary_factory = klass.primary_factory
        primary_factory_name = primary_factory.collect {|h| h[:keyword] }.join("").gsub(":", "_")
        primary_factory_args = primary_factory.collect {|h| "NewspeakObject #{h[:var]}" }.join(", ")
        file << "package #{package.gsub("/", ".")};" <<
          "public #{class_name}Class extends NewspeakClass {" <<
            "public TheWorldClass(NewspeakObject scope) { super(scope); }" <<
            "public TheWorld neu() { return new TheWorld(this); }" <<
            "public #{class_name} #{primary_factory_name}(#{primary_factory_args}) {" <<
              "// TODO: method" <<
            "}" <<
          "}"
        file.close
      end

      def parse(code)
        @transformer.apply file_out.parse(code)
      end

      alias squeak_keyword_expression keyword_expression
      rule :keyword_expression do
        (binary_object.maybe.as(:on) >> keyword_send.as(:send).with(:type => :direct)).as(:call)
      end

      alias squeak_binary_expression binary_expression
      rule :binary_expression do
        (unary_object.maybe.as(:on) >> (separator? >> binary_send).repeat(1).as(:send).with(:type => :chain)).as(:call)
      end

      alias squeak_unary_expression unary_expression
      rule :unary_expression do
        (primary.maybe.as(:on) >> (separator? >> unary_send).repeat(1).as(:send).with(:type => :chain)).as(:call)
      end

      rule :unary_object do
        unary_expression | primary
      end

      rule :primary do
        literal | block | brace_expression | (`(` >> expression >> `)`)
      end

      rule :newline do
        (`\r\n` | `\n` | `\r`)
      end

      rule :assignment do
        variable_name >> separator? >> (`=`)
      end

      rule :expression do
        # Newspeak only allows assignments in variable definitions
        # Afterwards, assignments are only possible using slot accessors
        normal_expression.as(:expr)
      end

      rule :locals do
        (`|` >> separator? >> (((assignment_expression >> `.`) | variable_name ) >> separator?).repeat >> `|`)
      end

      rule :ns_method_block do
        separator? >> `(` >> separator? >> code_body >> separator? >> `)` >> separator?
      end

      rule :ns_method_assignment do
        separator? >> `=` >> ns_method_block
      end

      rule :method do
        method_header >> ns_method_assignment
      end

      rule :category do
        string.as(:name) >> newline >> separator? >> (method >> separator?).repeat(1).as(:methods)
      end

      rule :class_assignment do
        separator? >> `=` >> separator? >> capital_identifier.maybe.as(:superclass) >> ns_method_block
      end

      rule :class_initializer do
        keyword_method_header.maybe.as(:primary_factory) >> class_assignment
      end

      rule :class_header do
        `class` >> separator >> capital_identifier.as(:class_name) >> separator >> class_initializer
      end

      rule :class_body do
        `(` >> separator? >> (class_definition).repeat.as(:nested_classes) >> separator? >> category.repeat.as(:categories) >> separator? >> `)`
      end

      rule :class_definition do
        class_header.as(:class_header) >> class_body.as(:class_body)
      end

      rule :file_out do
        str(FormatVersion) >> newline.repeat(1) >> string.as(:class_category) >> newline.repeat(1) >> class_definition >> separator?
      end
    end
  end
end
