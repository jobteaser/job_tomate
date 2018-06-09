# frozen_string_literal: true

module JobTomate
  module Values
    module JIRA

      # A value object to encapsulate JIRA issue data.
      # TODO: make immutable
      class Issue
        attr_reader :data

        CUSTOM_FIELDS_MAPPING = {
          "developer_backend" => "customfield_10600",
          "reviewer" => "customfield_10601",
          "product_manager" => "customfield_11200",
          "bug_cause" => "customfield_11101",
          "developer_frontend" => "customfield_12404",
          "branch_name" => "customfield_12900"
        }.freeze

        # Returns the JIRA field for a custom field.
        # @param custom_field [String] name of the custom field
        #   as used within JobTomate
        #
        # Usage:
        #
        #   Issue.jira_field("developer_backend")
        #   # => "customfield_10600"
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

        def issue_type
          data["fields"]["issuetype"]["name"]
        end

        def assignee_name
          value = data["fields"]["assignee"]
          value ? value["name"] : nil
        end

        def reporter_name
          data.dig("fields", "reporter", "name")
        end

        def assignee_user
          user_for_name(assignee_name)
        end

        def developer_backend_name
          value = custom_field("developer_backend")
          value ? value["name"] : nil
        end

        def reviewer_name
          value = custom_field("reviewer")
          value ? value["name"] : nil
        end

        def product_manager_name
          value = custom_field("product_manager")
          value ? value["name"] : nil
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

        def bug?
          issue_type == "Bug"
        end

        def bug_cause?
          !custom_field("bug_cause").nil?
        end

        def missing_pull_request?
          return true unless got_comments?
          comments = data["fields"]["comment"]["comments"].map do |comment_data|
            JobTomate::Values::JIRA::Comment.build(comment_data)
          end
          comments.each { |c| return false if c.pull_request? }
          true
        end

        def got_comments?
          return false if data["fields"]["comment"].blank?
          data["fields"]["comment"]["comments"].any?
        end
      end
    end
  end
end
