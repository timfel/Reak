require 'forwardable'

module Reak
  module Syntax
    class ClassHeader < Node
      attr_accessor :superclass, :name, :factory

      def initialize(name, superclass, factory)
        @name = name
        @superclass = superclass
        @factory = factory
        factory.header = self
      end
    end

    class ClassBody < Node
      attr_accessor :categories, :nested_classes

      def initialize(categories, nested_classes)
        @categories = Array(categories)
        if nested_classes
          nested_classes = Array(nested_classes)
          @nested_classes = nested_classes.collect do
            |c| Class.new(c)
          end
        else
          @nested_classes = []
        end
      end

      def methods
        @categories.collect(&:methods).flatten
      end
    end

    class Class < Node
      extend Forwardable
      attr_accessor :category, :header, :body, :outer

      def initialize(category, header, body, outer = nil)
        @category = category
        @header = header
        @body = body
        @outer = outer
      end

      def_delegators :@header, :name, :superclass, :factory, :instance_variables
      def_delegators :@body, :methods, :nested_classes

      def accept(visitor)
        visitor.visit_class(category.value, name, superclass, factory, methods || [], nested_classes || [])
      end
    end

    class NestedClass < Node
      def initialize(klass)
        @klass = klass
      end

      def accept(visitor)
        nested_visitor = visitor.class.new(visitor.klass, visitor.package)
        @klass.accept(nested_visitor)
        visitor.visit_class_method(klass.name)
      end
    end

    class ClassFactory < Node
      extend Forwardable
      attr_accessor :message, :locals, :body, :header

      def initialize(message, locals, body)
        @message = message
        @locals = locals
        @body = body
        if locals and body.respond_to? :statements
          body.statements += locals
        end
      end

      def accept(visitor)
        visitor.visit_factory(header.name, selector, args, locals || [], body)
      end

      def_delegators :@message, :selector, :args
    end
  end
end
