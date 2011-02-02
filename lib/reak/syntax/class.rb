require 'forwardable'

module Reak
  module Syntax
    class ClassHeader < Node
      attr_accessor :instance_variables, :superclass, :name, :primary_factory

      def initialize(name, superclass, ivars)
        @name = name
        @superclass = superclass
        @instance_variables = Array(ivars)
      end
    end

    class ClassBody < Node
      attr_accessor :categories, :nested_classes

      def initialize(categories, nested_classes)
        @categories = Array(categories)
        @nested_classes = Array(nested_classes)
      end

      def methods
        @categories.collect(&:methods).flatten
      end
    end

    class Class < Node
      attr_accessor :category, :header, :body, :outer

      def initialize(category, header, body, outer = nil)
        @category = category
        @header = header
        @body = body
        @outer = outer
      end

      def_delegator :@header, :name, :superclass, :primary_factory, :instance_variables
      def_delegator :@body, :methods, :nested_classes
    end
  end
end
