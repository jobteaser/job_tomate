require "mongoid"
require "config/mongo"
require "values/webhook"

module JobTomate
  module Data

    # Used to store a webhook payload in the database.
    #
    # NB: the `script/cleanup_stored_webhooks_and_requests.rb` script must be run regularly
    # to cleanup the database.
    class StoredWebhook
      include Mongoid::Document
      include Mongoid::Timestamps

      field :headers, type: Hash
      field :body, type: String

      index(created_at: 1)
      store_in collection: "stored_webhooks"

      # @return [Values::Webhook]
      def value
        Values::Webhook.new(headers, body)
      end
    end
  end
end
