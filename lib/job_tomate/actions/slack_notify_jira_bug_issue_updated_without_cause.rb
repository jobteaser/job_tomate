require "data/user"
require "support/service_pattern"

module JobTomate
  module Actions

    # Notifies the JIRA issue's assignee on Slack.
    class SlackNotifyJIRABugIssueUpdatedWithoutCause
      extend ServicePattern

      # @param issue [Values::JIRA::Issue]
      def run(issue)
        return if issue.assignee_user.nil?
        if issue.assignee_user.slack_username.blank?
          LOGGER.warn "unknown Slack username for user ##{issue.assignee_user.id}"
          return
        end

        link = "<#{issue.link}|#{issue.key}>"
        message = "The bug issue you're working on doesn't have a cause specified. Please do something about it! #{link} (#{issue.status})"
        Commands::Slack::SendMessage.run(
          message,
          channel: "@#{issue.assignee_user.slack_username}",
          username: 'Bug Monster',
          icon_emoji: ':smiling_imp:'
        )
      end
    end
  end
end
