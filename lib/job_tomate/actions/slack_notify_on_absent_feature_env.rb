# frozen_string_literal: true
require "data/user"
require "support/service_pattern"

module JobTomate
  module Actions

    # Notifies the JIRA issue's assignee on Slack.
    class SlackNotifyOnAbsentFeatureEnv
      extend ServicePattern

      # @param issue [Values::JIRA::Issue]
      def run(issue, changelog, username)
        return unless notify_on_feature_env?(issue, changelog)
        slack_username = slack_user(username)

        if slack_username.blank?
          LOGGER.warn "unknown Slack username for user ##{username}"
          return
        end
        send_message(issue, changelog, slack_username)
      end

      def send_message(issue, changelog, slack_username)
        link = "<#{issue.link}|#{issue.key}>"
        message = "This JIRA issue #{link} (#{changelog.to_string}) requires a feature env. Why don't you add it?"
        Commands::Slack::SendMessage.run(
          message,
          channel: "@#{slack_username}",
          username: "Feature Environmentor",
          icon_emoji: ":anchor:"
        )
      end

      def notify_on_feature_env?(issue, changelog)
        issue.missing_feature_env?(changelog)
      end

      def slack_user(username)
        user = Data::User.where(jira_username: username).first
        raise Errors::JIRA::UnknownUser, "no user with jira_username == \"#{username}\"" if user.nil?
        user.slack_username
      end
    end
  end
end
