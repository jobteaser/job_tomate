require "job_tomate/commands/base"
require "job_tomate/data/toggl_entry"

module JobTomate
  module Commands
    module Toggl

      # Updates an existing `TogglEntry` using the specified
      # Toggl report.
      #
      # NB: this assumes the passed entry has been updated, and
      # will not check it before performing the update
      # operation.
      class UpdateEntry < Commands::Base
        HISTORISED_FIELDS = %i(
          status
          toggl_description
          toggl_started
          toggl_updated
          toggl_duration
          toggl_user
          jira_issue_key
          jira_worklog_id
        )

        ENTRY_BASE = {
          status: "pending",
          jira_worklog_id: nil
        }

        def run(entry, report)
          update_entry_history(entry)
          update_entry_attributes(entry, report)
          entry.save
          entry
        end

        private

        # NB: DUPLICATE create_entry
        def update_entry_attributes(entry, report)
          entry.attributes = ENTRY_BASE.merge(
            toggl_id: report["id"],
            toggl_description: report["description"],
            toggl_started: Time.parse(report["start"]),
            toggl_updated: Time.parse(report["updated"]),
            toggl_duration: report["dur"] / 1000,
            toggl_user: report["user"],
            jira_issue_key: jira_issue_key(report)
          )
        end

        # Adds an item to the entry"s history
        # by appending an hash of the current
        # historised values.
        def update_entry_history(entry)
          history_item = entry.attributes.slice(*HISTORISED_FIELDS)
          history_item.merge!(time: Time.now)
          entry.history = entry.history + [history_item]
        end

        # NB: DUPLICATE create_entry
        def jira_issue_key(report)
          key = report["description"][/jt-[\d]+/i]
          return nil if key.nil?
          key.downcase
        end
      end
    end
  end
end
