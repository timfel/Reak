module Reak
  module Parser
    class Newspeak < Squeak

      FormatVersion = "Newsqueak2"

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
        string >> newline >> separator? >> (method >> separator?).repeat(1)
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
        `(` >> separator? >> (class_header >> class_body).repeat >> separator? >> category.repeat >> separator? >> `)`
      end

      rule :class_definition do
        class_header >> class_body
      end

      rule :file_out do
        str(FormatVersion) >> newline.repeat(1) >> string >> newline.repeat(1) >> class_definition >> separator?
      end
    end
  end
end
