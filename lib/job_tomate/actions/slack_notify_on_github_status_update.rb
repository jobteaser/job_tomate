require "commands/slack/send_message"
require "errors/github"
require "errors/slack"
require "support/service_pattern"

module JobTomate
  module Actions

    # Run on Github status update event to notify the corresponding user
    # (the sender of status' pull request).
    class SlackNotifyOnGithubStatusUpdate
      extend ServicePattern

      # @param issue [Values::Github::Status]
      def run(status)
        user = status.sender_user
        raise_unknown_github_user(status.sender_github_user) if user.nil?

        slack_username = user.slack_username
        raise_missing_slack_username(user) if slack_username.blank?

        send_message(slack_username, status)
      end

      private

      def raise_unknown_github_user(github_user)
        raise Errors::Github::UnknownUser, "Unknown user with github_user '#{github_user}'"
      end

      def raise_missing_slack_username(user)
        raise Errors::Slack::MissingUsername, "Missing 'slack_username' for user with ID '#{user.id}'"
      end

      def send_message(slack_username, status)
        message = "[#{status.branch}] #{status.context} - #{status.description}"
        Commands::Slack::SendMessage.run(
          message,
          channel: "@#{slack_username}"
        )
      end
    end
  end
end
