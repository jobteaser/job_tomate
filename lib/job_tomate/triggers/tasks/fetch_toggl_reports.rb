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

        # @param since_date [Date] defaults to 2 days ago
        # @param until_date [Date] defaults to today
        #
        # Default values are required for Tasks::SomeTask.run method so that
        # it may be started from the command line inside a cron or another
        # scheduler (e.g. Heroku Scheduler).
        def self.run(since_date = 2.days.ago.to_date, until_date = Date.today)
          reports = Commands::Toggl::FetchReports.run(since_date, until_date)
          process_reports(reports)
        end

        def self.process_reports(reports)
          reports.each do |report|
            entry = Commands::Toggl::FindEntry.run(report)
            if entry.nil?
              create_entry(entry, report)
            elsif entry_updated?(entry, report)
              update_entry(entry, report)
            end
          end
        end

        def self.create_entry(entry, report)
          entry = Commands::Toggl::CreateEntry.run(report)
          Events::Toggl::EntryCreated.run(entry)
        end

        def self.update_entry(entry, report)
          entry = Commands::Toggl::UpdateEntry.run(entry, report)
          Events::Toggl::EntryUpdated.run(entry)
        end

        def self.entry_updated?(entry, report)
          entry.present? && entry.toggl_updated < Time.parse(report["updated"])
        end
      end
    end
  end
end
