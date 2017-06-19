# frozen_string_literal: true

require "commands/slack/send_message"
require "support/service_pattern"

module JobTomate
  module Actions

    # Notifies the assigned developer that (s)he has forgotten
    # to create a pull request for the issue in review (passed as argument)
    class SlackNotifyMissingPullRequest
      extend ServicePattern
      # @param issue [Values::JIRA::Issue]
      # @param issue [Values::JIRA::Changelog]
      # @param user_name [String]
      def run(issue, changelog, username)
        return unless missing_pull_request?(issue, changelog)
        slack_user = slack_username(username)
        return if slack_user.nil?
        link = "<#{issue.link}|#{issue.key}>"
        message = "You have probably forgotten to create a pull request for this issue In Review => #{link}"
        Commands::Slack::SendMessage.run(
          message,
          channel: "@#{slack_user}",
          username: "Git Patrol",
          icon_emoji: ":rotating_light:"
        )
      end

      def missing_pull_request?(issue, changelog)
        return false unless changelog.requires_pull_request?
        issue.missing_pull_request?
      end

      def slack_username(username)
        user = Data::User.find_by(jira_username: username)
        raise Errors::JIRA::UnknownUser, "no user with jira_username == \"#{username}\"" if user.nil?
        user.slack_username
      end
    end
  end
end
