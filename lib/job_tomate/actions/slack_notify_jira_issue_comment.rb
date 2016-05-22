require "commands/slack/send_message"
require "support/service_pattern"

module JobTomate
  module Actions

    # Analyzes a JIRA comment (the "comment" value
    # of the JIRA"s issue updated webhook payload)
    # and forwards the comment to any mentioned user
    # known on Slack.
    class SlackNotifyJIRAIssueComment
      extend ServicePattern

      # @param comment [Values::JIRA::Issue]
      # @param comment [Values::JIRA::Comment]
      def run(issue, comment)
        comment.mentioned_users.each do |user|
          next if user.slack_username.blank?

          link = "<#{issue.link}|#{issue.key}>"
          message = "You have been mentioned in a comment on #{link}: *#{comment.body_for_slack}*"
          Commands::Slack::SendMessage.run(
            message,
            channel: "@#{user.slack_username}"
          )
        end
      end
    end
  end
end
