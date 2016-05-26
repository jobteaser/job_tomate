require "mongoid"
require "config/mongo"

module JobTomate
  module Data

    # Used to store a request and its response in the database.
    #
    # This is currently only used in `Commands::JIRA::Client`. This can be used
    # to store requests for other clients too.
    #
    # NB: the `script/cleanup_stored_webhooks_and_requests.rb` script must be run regularly
    # to cleanup the database.
    class StoredRequest
      include Mongoid::Document
      include Mongoid::Timestamps

      field :request_verb, type: String
      field :request_url, type: String
      field :request_options, type: Hash
      field :response_status, type: Integer
      field :response_headers, type: Hash
      field :response_body, type: String

      index(created_at: 1)
      store_in collection: "stored_requests"

      FIXTURES_DIR = File.expand_path("./spec/support/fixtures/stored_requests").freeze

      # Writes the stored request to a fixture file in `spec/support/fixtures/stored_requests`.
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
