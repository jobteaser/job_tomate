# frozen_string_literal: true
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
      FILTERED_DESCRIPTION_PATTERNS = [
        /Code Climate is analyzing this code/
      ].freeze

      # @param issue [Values::Github::Status]
      def run(status)
        user = status.author_user
        raise_unknown_github_user(status.author_github_user) if user.nil?

        slack_username = user.slack_username
        raise_missing_slack_username(user) if slack_username.blank?

        return if filtered_description?(status)

        send_message(slack_username, status)
      end

      private

      def filtered_description?(status)
        FILTERED_DESCRIPTION_PATTERNS.each do |regexp|
          return true if status.description =~ regexp
        end
        false
      end

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
