require "support/service_pattern"

module JobTomate
  module Events
    module JIRA

      # Handles JIRA issue created events.
      class IssueCreated
        extend ServicePattern

        # @param issue [Values::Issue]
        def run(issue); end
      end
    end
  end
end
