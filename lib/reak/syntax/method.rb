module Reak
  module Syntax
    class Method < Node
      attr_accessor :selector, :parameters, :locals, :body

      def initialize(selector, parameters, locals, body)
        @selector = selector
        @parameters = Array(parameters)
        @locals = Array(locals)
        @body = body
      end
    end
  end
end