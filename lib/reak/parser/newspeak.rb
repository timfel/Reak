module Reak
  module Parser
    class Newspeak < Squeak

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

      rule :class_assignment do
        separator? >> `=` >> separator? >> capital_identifier.maybe >> ns_method_block
      end

      rule :class_initializer do
        keyword_method_header.maybe >> class_assignment
      end

      rule :class_header do
        `class` >> separator >> capital_identifier >> separator >> class_initializer
      end

      rule :category do
        `(` >> string >> separator >> (method >> separator?).repeat >> `)`
      end
    end
  end
end
