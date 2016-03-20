require "actions/jira_update_issue_assignee_for_status"
require "data/user"
require "errors/jira"

module JobTomate
  module Events
    module JIRA

      # Trigger actions for a JIRA issue "status" change.
      class IssueUpdatedStatus
        attr_reader :changelog
        attr_reader :issue

        # @param issue [Values::JIRA::Issue]
        # @param issue [Values::JIRA::Changelog]
        def self.run(issue, changelog)
          new(issue, changelog).run
        end

        def initialize(issue, changelog)
          @issue = issue
          @changelog = changelog
        end

        def run
          Actions::JIRAUpdateIssueAssigneeForStatus.run(issue)
        end

        private

        def new_status
          changelog.to_string
        end
      end
    end
  end
end
