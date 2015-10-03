require 'active_support/all'
require 'job_tomate/interface/jira_client'

module JobTomate
  module Input
    module Jira

      # A set of helpers for Jira classes.
      # Usage:
      #   require 'job_tomate/input/jira_helpers'
      #   ...
      #   module Jira
      #     class SomeClass
      #       extend Helpers
      #   ...
      module Helpers

        JIRA_MAX_RESULTS = 1000
        JIRA_CATEGORIES = {
          'Maintenance' => :maintenance
        }

        # Performs a JIRA search with the specified JQL
        # query.
        def search(jql)
          JobTomate::Interface::JiraClient.exec_request(
            :get, '/search',
            ENV['JIRA_USERNAME'], ENV['JIRA_PASSWORD'],
            {}, # body
            jql: jql,
            startAt: 0,
            fields: 'id',
            maxResults: JIRA_MAX_RESULTS
          )
        end

        def issue_key(webhook_data)
          webhook_data['issue']['key']
        end

        def issue_category(webhook_data)
          jira_category = webhook_data['issue']['fields']['customfield_10400']['value']
          JIRA_CATEGORIES[jira_category]
        end

        # Returns true if the webhook has been called for
        # a new issue.
        def issue_created?(webhook_data)
          webhook_data['webhookEvent'] == 'jira:issue_created'
        end

        # Returns true if the webhook has been called
        # because the issue was changed on the specified
        # field.
        def issue_changed?(field, webhook_data)
          change(field, webhook_data).present?
        end

        # Returns the changelog item for the specified field
        # (first encountered)
        def change(field, webhook_data)
          key = issue_key(webhook_data)

          changelog = webhook_data['changelog']
          if changelog.blank? || (items = changelog['items']).empty?
            LOGGER.debug "No changelog or changelog items for issue #{key}"
            return nil
          end

          items.find { |item| item['field'] == field }
        end

        # @return [JobTomate::User] for the specified JIRA username
        def self.user_for_jira_username(jira_username)
          User.where(jira_username: jira_username).first
        end
      end
    end
  end
end
