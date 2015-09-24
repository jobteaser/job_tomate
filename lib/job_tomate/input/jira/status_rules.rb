require 'active_support/all'
require 'job_tomate/input/jira/helpers'

module JobTomate
  module Input
    module Jira

      # Perform actions based on status changes:
      #   - set people (assignee, developer and reviewer),
      #   - notify newly assigned user in Slack.
      class StatusRules
        extend Helpers

        DEFAULT_FOR_FUNCTIONAL_REVIEW = %w(
          harold.sirven
          christophe.colard
        )
        ACCEPTED_FOR_FUNCTIONAL_REVIEW = DEFAULT_FOR_FUNCTIONAL_REVIEW +
          %w(romain.champourlier)
        JIRA_ISSUE_URL_BASE = 'https://jobteaser.atlassian.net/browse'

        # Applies the rules
        def self.apply(webhook_data)
          notify_new_assignee(webhook_data)
          update_people(webhook_data)
        end

        # Notify new assignee on Slack
        def self.notify_new_assignee(webhook_data)
          key = issue_key(webhook_data)
          assignee_change = change('assignee', webhook_data)
          if assignee_change.nil?
            LOGGER.debug "No assignee change for issue #{key}"
            return
          end

          assignee_jira_username = assignee_change['to']
          return if assignee_jira_username.nil?

          assignee = user_for_jira_username(assignee_jira_username)
          if assignee.nil?
            LOGGER.warn "Could not find user for JIRA username \"#{assignee_jira_username}\""
            return
          end

          assignee_slack_username = assignee.slack_username
          if assignee_slack_username.nil?
            LOGGER.warn "Slack username not set for user #{assignee_jira_username}"
            return
          end

          message = "You've been assigned to #{slack_link_for_jira_issue(key)}"
          Output::SlackWebhook.send(message, channel: "@#{assignee_slack_username}")
        end

        def self.update_people(webhook_data)
          key = issue_key(webhook_data)
          status_change = change('status', webhook_data)
          if status_change.nil?
            LOGGER.debug "No status change for issue #{key}"
            return
          end

          new_status = status_change['toString']
          webhook_username = webhook_data['user']['key']
          developer_jira_username = webhook_data['issue']['fields']['customfield_10600'].try(:[], 'key')
          reviewer = webhook_data['issue']['fields']['customfield_10601'].try(:[], 'key')
          functional_reviewer = determine_functional_reviewer(webhook_data)

          webhook_user = JobTomate::User.where(jira_username: webhook_username).first
          if webhook_user.nil?
            LOGGER.warn "User with JIRA username \"#{webhook_username}\" is unknown"
            webhook_user = JobTomate::User.first
            LOGGER.warn "Falling back to JIRA user \"#{webhook_user.jira_username}\""
          end

          if developer_jira_username.nil? && (new_status == 'Ready for Release' || new_status == 'In Development')
            developer_jira_username = webhook_data['user']['name']
          end
          if (reviewer.nil? && new_status == 'In Review') && webhook_data['user']['name'] != developer_jira_username
            reviewer = webhook_data['user']['name']
          end

          assignee_jira_username = (
            case new_status
            when 'In Development' then developer_jira_username
            when 'In Functional Review' then functional_reviewer
            when 'In Review' then reviewer
            when 'Ready for Release' then developer_jira_username
            end
          )

          Output::JiraClient.set_people(
            key,
            webhook_user.jira_username,
            webhook_user.jira_password,
            assignee_jira_username,
            developer_jira_username,
            reviewer)
        end

        # IMPLEMENTATION

        def self.reporter_jira_username(webhook_data)
          webhook_data['issue']['fields']['reporter']['key']
        end

        def self.determine_functional_reviewer(webhook_data)
          issue_reporter = reporter_jira_username(webhook_data)
          if issue_reporter.present? &&
            issue_reporter.in?(ACCEPTED_FOR_FUNCTIONAL_REVIEW)
            return issue_reporter
          end
          DEFAULT_FOR_FUNCTIONAL_REVIEW.sample
        end

        def self.user_for_jira_username(jira_username)
          User.where(jira_username: jira_username).first
        end

        # Returns a String usable in a Slack message to
        # present a link to a JIRA issue.
        def self.slack_link_for_jira_issue(issue_key)
          "<#{JIRA_ISSUE_URL_BASE}/#{issue_key}|#{issue_key}>"
        end
      end
    end
  end
end
