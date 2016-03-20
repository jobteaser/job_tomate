module JobTomate
  module Triggers
    module Webhooks

      # Superclass for webhooks handlers
      class Base
        attr_accessor :request

        def webhook_data
          @webhook_data = (
            request.body.rewind
            json = request.body.read
            json.empty? ? { error: "no body" } : JSON.parse(json)
          )
        end
      end
    end
  end
end
