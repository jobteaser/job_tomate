require "job_tomate/commands/toggl/create_or_update_entry_from_report"
require "job_tomate/commands/toggl/fetch_reports"
require "job_tomate/commands/toggl/process_pending_entries"
require "job_tomate/workflows"

module JobTomate
  module Workflows

    # Add worklogs to JIRA issues according to the reports
    # fetched from Toggl.
    class TogglReportsToJiraWorklogs < BaseWorkflow

      def self.run(since_date_str, until_date_str = Date.today.to_s)
        since_date = Date.parse(since_date_str)
        until_date = Date.parse(until_date_str)
        reports = Commands::Toggl::FetchReports.run(since_date, until_date)
        reports.each do |report|
          Commands::Toggl::CreateOrUpdateEntryFromReport.run(report)
        end
        Commands::Toggl::ProcessPendingEntries.run
      end
    end
  end
end
