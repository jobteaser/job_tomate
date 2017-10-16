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

      # Array, to filter message that should be sent, where
      #   - first value are regex for status.context
      #   - second value are regex for status.description
      #
      # For code climate, we want to send message for
      #   - the result of the analyse
      #
      # For CircleCI, we want to send message for
      #   - failed test
      #   - first passed test of the workflow
      #   - two last test of the workflow
      WHITELIST_STATUS_REGEX = [
        [%r{codeclimate}, %r{to fix}],
        [%r{codeclimate}, %r{All good!}],
        [%r{ci/circleci}, %r{Your tests failed on CircleCI}],
        [%r{ci/circleci: checkout_code}, %r{Your tests passed on CircleCI!}],
        [%r{ci/circleci: ruby_integration_test_1}, %r{Your tests passed on CircleCI!}],
        [%r{ci/circleci: ruby_integration_test_2}, %r{Your tests passed on CircleCI!}]
      ].freeze
      private_constant :WHITELIST_STATUS_REGEX

      # @param status [Values::Github::Status]
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

        return unless whitelist_status?(status)

        send_message(slack_username, status)
      end

      private

      def user_for_github_login(login)
        JobTomate::Data::User.where(github_user: login).first
      end

      def whitelist_status?(status)
        WHITELIST_STATUS_REGEX.any? do |context_regex, description_regex|
          status.context =~ /#{context_regex}/ && status.description =~ /#{description_regex}/
        end
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
