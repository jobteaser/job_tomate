require "events/toggl/helpers"
require "support/service_pattern"

module JobTomate
  module Events
    module Toggl

      # Event for TogglEntry update (occurs when
      # a new Toggl report has been fetched and an
      # existing TogglEntry was updated).
      class UpdatedReport
        extend ServicePattern
        include Helpers

        # @param entry [Data::TogglEntry]
        def run(entry)
          @entry = entry
          return update_entry_not_related_to_jira unless related_to_jira?
          return create_worklog_and_update_entry unless previous_worklog?
          return update_entry_unchanged_issue unless changed_issue?
          update_entry_changed_issue
        end

        private

        def previous_worklog?
          return false if entry.history.empty?
          entry.history.last["jira_worklog_id"].present?
        end

        def changed_issue?
          entry.history.last["jira_issue_key"] != entry.jira_issue_key
        end

        # Entry with prior worklog that was just updated
        def update_entry_unchanged_issue
          update_worklog_and_update_entry
        end

        # Entry with an history with a worklog on another
        # issue.
        def update_entry_changed_issue
          delete_previous_worklog
          create_worklog_and_update_entry
        end
      end
    end
  end
end
