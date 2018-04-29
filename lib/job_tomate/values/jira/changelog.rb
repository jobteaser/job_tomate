require "errors/jira"
require "values/jira/issue"

module JobTomate
  module Values
    module JIRA

      # A value object to encapsulate JIRA changelog.
      class Changelog
        attr_reader :data

        CUSTOM_FIELDS_MAPPING = {
          "Developer" => "developer",
          "Reviewer" => "reviewer",
          "Feature Owner" => "product_manager"
        }

        # @param data [Hash] the "changelog" values from
        #   the JIRA webhook payload.
        def self.build(data)
          new(data)
        end

        def initialize(data)
          @data = data
        end

        def from
          data["from"]
        end

        def from_string
          data["fromString"]
        end

        def to
          data["to"]
        end

        def to_string
          data["toString"]
        end

        def field
          return mapped_field if data["fieldtype"] == "custom"
          data["field"]
        end

        def mapped_field
          src = data["field"]
          dst = CUSTOM_FIELDS_MAPPING[src]
          return dst if dst
          fail Errors::JIRA::UnknownCustomField, "no mapping for \"#{src}\" in Values::JIRA::Changelog"
        end
      end
    end
  end
end
