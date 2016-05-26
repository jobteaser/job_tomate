require "mongoid"
require "config/mongo"

module JobTomate
  module Data

    # Used to store a webhook payload in the database.
    #
    # NB: the `script/cleanup_stored_webhooks_and_requests.rb` script must be run regularly
    # to cleanup the database.
    class StoredWebhook
      include Mongoid::Document
      include Mongoid::Timestamps

      field :source, type: String
      field :data,   type: Hash

      index(created_at: 1)
      store_in collection: "stored_webhooks"
    end
  end
end
