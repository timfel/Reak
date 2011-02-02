module Reak
  module Syntax
    class Category < Node
      attr_accessor :name, :methods

      def initialize(name, methods)
        @name = name
        @methods = Array(methods)
      end
    end
  end
end
