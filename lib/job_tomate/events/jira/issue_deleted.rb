require "support/service_pattern"

module JobTomate
  module Events
    module JIRA

      # Handles JIRA issue deleted events.
      class IssueDeleted
        extend ServicePattern

        # Does nothing at the moment.
        # @param issue [Values::Issue]
        def self.run(_issue)
        end
      end
    end
  end
end
