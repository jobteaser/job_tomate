module JobTomate
  module Values
    module JIRA

      # A value object to encapsulate JIRA issue data.
      # TODO: make immutable
      class Issue
        attr_reader :data

        CUSTOM_FIELDS_MAPPING = {
          "developer" => "customfield_10600",
          "reviewer" => "customfield_10601",
          "feature_owner" => "customfield_11200"
        }

        # Returns the JIRA field for a custom field.
        # @param custom_field [String] name of the custom field
        #   as used within JobTomate
        def self.jira_field(custom_field)
          CUSTOM_FIELDS_MAPPING[custom_field]
        end

        # @param issue_key [String] the JIRA issue key
        def self.build(issue_data)
          new(issue_data)
        end

        def initialize(issue_data)
          @data = issue_data
        end

        def key
          data["key"]
        end

        def link
          "#{ENV['JIRA_BROWSER_ISSUE_PREFIX']}/#{key}"
        end

        def status
          data["fields"]["status"]["name"]
        end

        def priority
          data["fields"]["priority"]["name"]
        end

        def blocker?
          priority == "Blocker"
        end

        # The issue category (JobTeaser custom field).
        # May be Roadmap, Quickwin, Maintenance, Technical, Operational.
        # @return [String]
        def category
          data["fields"]["customfield_10400"]["name"]
        end

        def maintenance?
          category == "Maintenance"
        end

        def assignee_name
          value = data["fields"]["assignee"]
          value ? value["name"] : nil
        end

        def assignee_user
          user_for_name(assignee_name)
        end

        def developer_name
          value = custom_field("developer")
          value ? value["name"] : nil
        end

        def developer_user
          user_for_name(developer_name)
        end

        def reviewer_name
          value = custom_field("reviewer")
          value ? value["name"] : nil
        end

        def reviewer_user
          user_for_name(reviewer_name)
        end

        def feature_owner_name
          value = custom_field("feature_owner")
          value ? value["name"] : nil
        end

        def feature_owner_user
          user_for_name(feature_owner_name)
        end

        # @return [String] custom JIRA field for the specified
        #   mapped field
        def custom_field(mapped_field)
          custom_field = CUSTOM_FIELDS_MAPPING[mapped_field]
          fail UnknownCustomField, "no mapping for \"#{mapped_field}\" in Values::JIRA::Issue" if custom_field.nil?
          value = data["fields"][custom_field]
          return value if value
        end

        def user_for_name(username)
          return nil if username.blank?
          user = Data::User.where(jira_username: username).first
          fail Errors::JIRA::UnknownUser, "no user with jira_username == \"#{username}\"" if user.nil?
          user
        end
      end
    end
  end
end
