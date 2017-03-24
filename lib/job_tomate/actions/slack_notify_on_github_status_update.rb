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
      # @raise [Errors::Github::UnknownUser] if the status author's login
      #   does not match any user in the database.
      #
      # NB: The status payload may not contain an author login. In this
      #     case, it does nothing.
      def run(status)
        return if status.author_github_login.nil?
        user = user_for_github_login(status.author_github_login)
        raise_unknown_github_login(status.author_github_login) if user.nil?

        slack_username = user.slack_username
        raise_missing_slack_username(user) if slack_username.blank?

        return if filtered_description?(status)

        send_message(slack_username, status)
      end

      private

      def user_for_github_login(login)
        JobTomate::Data::User.where(github_user: login).first
      end

      def filtered_description?(status)
        FILTERED_DESCRIPTION_PATTERNS.each do |regexp|
          return true if status.description =~ regexp
        end
        false
      end

      def raise_unknown_github_login(login)
        raise Errors::Github::UnknownUser, "Unknown user with github login '#{login}'"
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
