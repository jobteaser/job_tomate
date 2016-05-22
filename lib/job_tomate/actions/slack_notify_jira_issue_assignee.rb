require "data/user"
require "support/service_pattern"

module JobTomate
  module Actions

    # Notifies the JIRA issue's assignee on Slack.
    class SlackNotifyJIRAIssueAssignee
      extend ServicePattern

      # @param issue [Values::JIRA::Issue]
      def run(issue)
        return if issue.assignee_user.nil?
        if issue.assignee_user.slack_username.blank?
          LOGGER.warn "unknown Slack username for user ##{issue.assignee_user.id}"
          return
        end

        link = "<#{issue.link}|#{issue.key}>"
        message = "You've been assigned to #{link} (#{issue.status})"
        Commands::Slack::SendMessage.run(
          message,
          channel: "@#{issue.assignee_user.slack_username}"
        )
      end
    end
  end
end
