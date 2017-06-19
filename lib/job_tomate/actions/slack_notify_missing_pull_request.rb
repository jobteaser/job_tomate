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
      def run(issue)
        # Not using the assignee cause in Issue 45
        user = issue.developer_user
        return if user.nil? || user.slack_username.nil?
        link = "<#{issue.link}|#{issue.key}>"
        message = "You have probably forgotten to create a pull request for this issue In Review => #{link}"
        Commands::Slack::SendMessage.run(
          message,
          channel: user.slack_username
        )
      end
    end
  end
end
