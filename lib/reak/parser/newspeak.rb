module Reak
  module Parser
    class Newspeak < Squeak

      FormatVersion = "Newsqueak2"

      def parse(code)
        @transformer.apply file_out.parse(code)
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
        string >> newline >> separator? >> (method >> separator?).repeat
      end

      rule :class_assignment do
        separator? >> `=` >> separator? >> capital_identifier.maybe >> ns_method_block
      end

      rule :class_initializer do
        keyword_method_header.maybe >> class_assignment
      end

      rule :class_header do
        `class` >> separator >> capital_identifier >> separator >> class_initializer
      end

      rule :class_body do
        `(` >> (class_header >> class_body).maybe >> category.repeat >> `)`
      end

      rule :class_definition do
        class_header >> class_body
      end

      rule :file_out do
        str(FormatVersion) >> newline >> capital_identifier >> newline >> class_definition
      end
    end
  end
end
