require "job_tomate/commands/base"
require "job_tomate/data/toggl_entry"

module JobTomate
  module Commands
    module Toggl

      # Creates a `TogglEntry` record from a report fetched
      # from the Toggl API (untouched).
      class CreateOrUpdateEntryFromReport < Commands::Base
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

        def run(report)
          toggl_id = report["id"]
          entry = Data::TogglEntry.where(toggl_id: toggl_id).first || Data::TogglEntry.new
          update_entry(entry, report)
        end

        private

        def update_entry(entry, report)
          return entry unless entry_updated?(entry, report)
          update_entry_history(entry)
          update_entry_attributes(entry, report)
          entry.save
          entry
        end

        # Returns true if the entry has been updated, i.e. the Toggl
        # report"s "updated" is newer than the entry"s.
        def entry_updated?(entry, report)
          return true if entry.new_record?
          entry.toggl_updated < Time.parse(report["updated"])
        end

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
          if entry.new_record?
            entry.history = []
            return
          end
          history_item = entry.attributes.slice(*HISTORISED_FIELDS)
          history_item.merge!(time: Time.now)
          entry.history = entry.history + [history_item]
        end

        def jira_issue_key(report)
          key = report["description"][/jt-[\d]+/i]
          return nil if key.nil?
          key.downcase
        end
      end
    end
  end
end
