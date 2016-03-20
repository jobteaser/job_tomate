require "job_tomate/commands/base"
require "job_tomate/data/toggl_entry"

module JobTomate
  module Commands
    module Toggl

      # Creates a `TogglEntry` record from a report fetched
      # from the Toggl API (untouched).
      class CreateEntry < Commands::Base

        ENTRY_BASE = {
          history: [],
          status: "pending"
        }

        def run(report)
          entry = Data::TogglEntry.new
          update_entry_attributes(entry, report)
          entry.save
          entry
        end

        private

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

        def jira_issue_key(report)
          key = report["description"][/jt-[\d]+/i]
          return nil if key.nil?
          key.downcase
        end
      end
    end
  end
end
