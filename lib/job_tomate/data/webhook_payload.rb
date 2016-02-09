require 'mongoid'
require 'config/mongo'

module JobTomate
  module Data

    # Store a webhook payload in database for a week for debugging.
    class WebhookPayload
      include Mongoid::Document
      include Mongoid::Timestamps

      field :source, type: String
      field :data,   type: Hash

      index(created_at: 1)
      store_in collection: 'webhook_payloads'
    end
  end
end
