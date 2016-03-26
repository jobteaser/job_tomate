module JobTomate
  module Events

    # A base class, handling boilerplate.
    class Base
      attr_reader :description

      def self.run(description)
        new(description).run
      end

      def initialize(description)
        @description = description
      end
    end
  end
end
