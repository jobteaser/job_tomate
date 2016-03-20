require "job_tomate/commands/base"
require "job_tomate/commands/jira/add_worklog"
require "job_tomate/commands/jira/delete_worklog"
require "job_tomate/commands/jira/update_worklog"
require "job_tomate/commands/toggl/create_or_update_entry_from_report"
require "job_tomate/commands/toggl/fetch_reports"
require "job_tomate/data/user"

module JobTomate
  module Commands
    module Toggl

      # Processes all `TogglEntry` records with the "pending" status.
      class ProcessPendingEntries < Commands::Base

        def run
          pending_entries = Data::TogglEntry.where(status: "pending")
          return if pending_entries.empty?

          pending_entries.each { |e| process_entry(e) }
        end

        private

        # Cases:
        #   - not related to jira
        #   - no history: new entry => create the worklog
        #   - history:
        #     - did not change issue key => update the worklog
        #     - did change the issue key => delete old worklog, create new one
        def process_entry(entry)
          return if handle_not_related_to_jira(entry)
          return if handle_no_history(entry)
          handle_with_history(entry)
        end

        # Handle case when the entry is not related to JIRA.
        def handle_not_related_to_jira(entry)
          return false unless entry.jira_issue_key.nil?
          entry.status = :not_related_to_jira
          entry.save
          true
        end

        # Entry with no history
        def handle_no_history(entry)
          return false unless entry.history.blank?
          status, worklog_id = create_worklog(entry)
          return if status == :error
          processed_entry_created_worklog!(entry, worklog_id)
        end

        def handle_with_history(entry)
          return if handle_updated_worklog(entry)
          handle_worklog_changed_issue(entry)
        end

        # Entry with an history and worklog that was just updated
        def handle_updated_worklog(entry)
          return false unless entry.history.last["jira_issue_key"] == entry.jira_issue_key
          status, worklog_id = update_worklog(entry)
          return if status == :error
          processed_entry_updated_worklog!(entry, worklog_id)
        end

        # Entry with an history with a worklog on another
        # issue.
        def handle_worklog_changed_issue(entry)
          delete_previous_worklog(entry)
          status, worklog_id = create_worklog(entry)
          return if status == :error
          processed_entry_created_worklog!(entry, worklog_id)
        end

        def processed_entry_created_worklog!(entry, worklog_id)
          entry.status = :synced_with_jira
          entry.jira_worklog_id = worklog_id
          entry.save
        end

        def processed_entry_updated_worklog!(entry, worklog_id)
          entry.status = :synced_with_jira
          entry.jira_worklog_id = worklog_id
          entry.save
        end

        def create_worklog(entry)
          username, password = jira_credentials(entry)
          Commands::Jira::AddWorklog.run(
            entry.jira_issue_key,
            username,
            password,
            entry.toggl_duration,
            entry.toggl_started
          )
        end

        def update_worklog(entry)
          username, password = jira_credentials(entry)
          worklog_id = entry.history.last["jira_worklog_id"]
          Commands::Jira::UpdateWorklog.run(
            entry.jira_issue_key,
            worklog_id,
            username,
            password,
            entry.toggl_duration,
            entry.toggl_started
          )
        end

        def delete_previous_worklog(entry)
          username, password = jira_credentials(entry)
          old_issue_key = entry.history.last["jira_issue_key"]
          old_worklog_id = entry.history.last["jira_worklog_id"]
          Commands::Jira::DeleteWorklog.run(
            old_issue_key,
            old_worklog_id,
            username,
            password
          )
        end

        def jira_credentials(entry)
          user = Data::User.where(toggl_user: entry.toggl_user).first
          user ? [user.jira_username, user.jira_password] : nil
        end
      end
    end
  end
end
