module Reak
  module Syntax
    class Expression < Node
      attr_accessor :expressions
      unfold

      def self.new(expressions)
        if expressions.size == 1 and expressions.first.unfold?
          expressions.first
        else
          super
        end
      end

      def initialize(expressions)
        @expressions = Array(expressions)
      end

      def to_sexp
        [:expr].concat @expressions.map { |e| e.to_sexp }
      end

      def accept(visitor)
        @expressions.collect {|e| e.accept(visitor) }.join("\n")
      end

      def visit(visitor)
        expressions.each do |exp|
          exp.visit visitor
        end
      end
    end
  end
end