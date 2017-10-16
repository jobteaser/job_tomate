# frozen_string_literal: true
require "commands/slack/send_message"
require "errors/slack"
require "support/service_pattern"

module JobTomate
  module Actions

    # Run on Github status update event to notify the corresponding user
    # (the sender of status' pull request).
    class SlackNotifyOnCircleciStatusUpdate
      extend ServicePattern

      # @param issue [string] either 'success' or 'failed'
      # @raise [Errors::Circleci::UnknownUser] if the status author's login
      #   does not match any user in the database.
      def run(status)
        return if status.author_github_login.nil?
        user = user_for_github_login(status.author_github_login)
        raise_unknown_github_login(status.author_github_login) if user.nil?

        slack_username = user.slack_username
        raise_missing_slack_username(user) if slack_username.blank?

        send_message(slack_username, status)
      end

      private

      def user_for_github_login(login)
        JobTomate::Data::User.where(github_user: login).first
      end

      def raise_unknown_github_login(login)
        raise Errors::Circleci::UnknownUser, "Unknown user with github login '#{login}'"
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
