require "actions/slack_notify_jira_bug_issue_without_cause_updated"
require "support/service_pattern"

module JobTomate
  module Events
    module JIRA

      # Notifies the developer if s/he has updated a status of a bug issue without specifying its cause.
      #
      # Description is an Hash with the following keys/values:
      #   - "issue_key": [String] the key of the commented issue
      #
      class BugIssueWithoutCauseUpdated
        extend ServicePattern

        # @param issue [Values::JIRA::Issue]
        def run(issue)
          Actions::SlackNotifyJIRABugIssueWithoutCauseUpdated.run(issue)
        end
      end
    end
  end
end
