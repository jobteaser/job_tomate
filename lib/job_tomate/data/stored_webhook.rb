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

      # Returns a webhook value object with the content of the stored
      # webhook.
      #
      # @return [Values::Webhook]
      def value
        Values::Webhook.new(headers, body)
      end

      # DUPLICATE of StoredRequest

      FIXTURES_DIR = File.expand_path("./spec/support/fixtures/stored_webhooks").freeze

      # Writes the stored webhook to a fixture file in `spec/support/fixtures/stored_webhooks`.
      # NB: intended for development / test purposes only.
      def write_to_fixture(name)
        File.open(self.class.file_path(name), "w") do |file|
          file.write to_yaml
        end
      end

      def self.load_from_fixture(name)
        YAML.load(File.read(file_path(name)))
      end

      def self.file_path(name)
        File.expand_path("#{FIXTURES_DIR}/#{name}.yml")
      end
    end
  end
end
