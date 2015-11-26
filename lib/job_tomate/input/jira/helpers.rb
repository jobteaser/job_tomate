require 'active_support/all'
require 'job_tomate/data/user'
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
        MAX_RESULTS = 1000
        CATEGORIES = {
          'Maintenance' => :maintenance
        }

        # TODO: move this configuration to database
        def_func_review_env_var = ENV['JIRA_DEFAULT_USERNAMES_FOR_FUNCTIONAL_REVIEW']
        acc_func_review_env_var = ENV['JIRA_ACCEPTED_USERNAMES_FOR_FUNCTIONAL_REVIEW']

        DEFAULT_FOR_FUNCTIONAL_REVIEW = def_func_review_env_var.split(',').map(&:strip)
        ACCEPTED_FOR_FUNCTIONAL_REVIEW = DEFAULT_FOR_FUNCTIONAL_REVIEW + acc_func_review_env_var.split(',').map(&:strip)

        ISSUE_URL_BASE = ENV['JIRA_ISSUE_URL_BASE']
        API_USERNAME = ENV['JIRA_USERNAME']
        API_PASSWORD = ENV['JIRA_PASSWORD']

        # Performs a JIRA search with the specified JQL
        # query.
        def search(jql)
          JobTomate::Interface::JiraClient.exec_request(
            :get, '/search',
            API_USERNAME, API_PASSWORD,
            {}, # body
            jql: jql,
            startAt: 0,
            fields: 'id',
            maxResults: MAX_RESULTS
          )
        end

        def issue_key(webhook_data)
          webhook_data['issue']['key']
        end

        def issue_category(webhook_data)
          jira_category = webhook_data['issue']['fields']['customfield_10400']['value']
          CATEGORIES[jira_category]
        end

        def issue_priority(webhook_data)
          webhook_data['issue']['fields']['priority']['name']
        rescue NoMethodError
          nil
        end

        # Returns true if the webhook has been called for
        # a new issue.
        def issue_created?(webhook_data)
          webhook_data['webhookEvent'] == 'jira:issue_created'
        end

        # Returns true if the webhook has been called for
        # an issue update.
        def issue_updated?(webhook_data)
          webhook_data['webhookEvent'] == 'jira:issue_updated'
        end

        # Returns true if the webhook has been called
        # because the issue was changed on the specified
        # field.
        def issue_changed?(field, webhook_data)
          issue_change(field, webhook_data).present?
        end

        # Returns the changelog item for the specified field
        # (first encountered)
        def issue_change(field, webhook_data)
          key = issue_key(webhook_data)

          changelog = webhook_data['changelog']
          if changelog.blank? || (items = changelog['items']).empty?
            LOGGER.debug "No changelog or changelog items for issue #{key}"
            return nil
          end

          change = items.find { |item| item['field'] == field }
          LOGGER.debug "Status change for issue #{key}: #{change}"
          change
        end

        # @return [JobTomate::Data::User] for the specified JIRA username
        def user_for_jira_username(jira_username)
          JobTomate::Data::User.where(jira_username: jira_username).first
        end

        def reporter_jira_username(webhook_data)
          webhook_data['issue']['fields']['reporter']['key']
        end

        def functional_reviewer_jira_username(webhook_data)
          issue_reporter = reporter_jira_username(webhook_data)
          if issue_reporter.present? &&
            issue_reporter.in?(ACCEPTED_FOR_FUNCTIONAL_REVIEW)
            return issue_reporter
          end
          DEFAULT_FOR_FUNCTIONAL_REVIEW.sample
        end

        # Returns a String usable in a Slack message to
        # present a link to a JIRA issue.
        def slack_link_for_jira_issue(issue_key)
          "<#{ISSUE_URL_BASE}/#{issue_key}|#{issue_key}>"
        end
      end
    end
  end
end
