# frozen_string_literal: true

require "data/user"
require "support/service_pattern"

module JobTomate
  module Actions

    # Notifies the JIRA issue's assignee on Slack.
    class SlackNotifyJIRABugIssueUpdatedWithoutCause
      extend ServicePattern

      # @param issue [Values::JIRA::Issue]
      def run(issue, username)
        return unless missing_bug_cause?(issue)
        user = slack_user(username)

        if user.nil?
          LOGGER.warn "unknown Slack username ##{username}"
          return
        end

        send_message(issue, user)
      end

      def send_message(issue, slack_user)
        link = "<#{issue.link}|#{issue.key}>"
        message =
          "The bug issue you're working on doesn't have a cause specified.
Please do something about it! #{link} (#{issue.status})"
        Commands::Slack::SendMessage.run(
          message,
          channel: "@#{slack_user}"
        )
      end

      def missing_bug_cause?(issue)
        issue.bug? && !issue.bug_cause?
      end

      def slack_user(username)
        user = Data::User.where(jira_username: username).first
        raise Errors::JIRA::UnknownUser, "no user with jira_username == \"#{username}\"" if user.nil?
        user.slack_username
      end
    end
  end
end
