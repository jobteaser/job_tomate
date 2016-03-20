require "actions/slack_notify_jira_issue_comment"

module JobTomate
  module Events
    module JIRA

      # Handles JIRA issue update events.
      #
      # Description is an Hash with the following keys/values:
      #   - "issue_key": [String] the key of the commented issue
      #   - "body": [String] the body of the comment
      #
      class IssueCommentAdded

        # @param issue [Values::JIRA::Issue]
        # @param comment [Values::JIRA::Comment]
        def self.run(issue, comment)
          Actions::SlackNotifyJIRAIssueComment.run(issue, comment)
        end
      end
    end
  end
end
