require "commands/toggl/create_entry"
require "commands/toggl/fetch_reports"
require "commands/toggl/find_entry"
require "commands/toggl/update_entry"
require "events/toggl/entry_created"
require "events/toggl/entry_updated"

module JobTomate
  module Triggers
    module Tasks

      # Add worklogs to JIRA issues according to the reports
      # fetched from Toggl.
      class FetchTogglReports

        def self.run(since_date_str, until_date_str = Date.today.to_s)
          since_date = Date.parse(since_date_str)
          until_date = Date.parse(until_date_str)
          reports = Commands::Toggl::FetchReports.run(since_date, until_date)
          process_reports(reports)
        end

        def self.process_reports(reports)
          reports.each do |report|
            entry = find_entry(report)
            if entry_updated?(entry, report)
              update_entry(entry, report)
              Events::Toggl::EntryUpdated.run(entry)
            else
              entry = create_entry(report)
              Events::Toggl::EntryCreated.run(entry)
            end
          end
        end

        def self.entry_updated?(entry, report)
          entry.present? && entry.toggl_updated < Time.parse(report["updated"])
        end

        def self.find_entry(report)
          Commands::Toggl::FindEntry.run(report)
        end

        def self.create_entry(report)
          Commands::Toggl::CreateEntry.run(report)
        end

        def self.update_entry(entry, report)
          Commands::Toggl::UpdateEntry.run(entry, report)
        end
      end
    end
  end
end
