require "data/user"
require "support/service_pattern"

module JobTomate
  module Actions

    # Notifies the JIRA issue's assignee on Slack.
    class SlackNotifyOnAbsentFeatureEnv
      extend ServicePattern

      # @param issue [Values::JIRA::Issue]
      def run(issue, changelog)
        if issue.assignee_user.slack_username.blank?
          LOGGER.warn "unknown Slack username for user ##{issue.assignee_user.id}"
          return
        end

        link = "<#{issue.link}|#{issue.key}>"
        message = "This JIRA issue #{link} (#{changelog.to_string}) requires a feature env. Why don't you add it?"
        Commands::Slack::SendMessage.run(
          message,
          channel: "@#{issue.assignee_user.slack_username}",
          username: "Feature Environmentor",
          icon_emoji: ":anchor:"
        )
      end
    end
  end
end
