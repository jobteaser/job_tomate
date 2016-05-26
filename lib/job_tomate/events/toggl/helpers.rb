require "commands/jira/add_worklog"
require "commands/jira/delete_worklog"
require "commands/jira/update_worklog"
require "data/user"
require "errors/jira"

module JobTomate
  module Events
    module Toggl

      # Contract:
      #   - #entry method returns [Data::TogglEntry]
      module Helpers

        def related_to_jira?
          entry.jira_issue_key.present?
        end

        def update_entry_not_related_to_jira
          entry.status = :not_related_to_jira
          entry.save!
          true
        end

        def add_worklog_and_update_entry
          worklog_id = add_worklog
          entry.status = :synced
          entry.jira_worklog_id = worklog_id
          entry.save
        rescue Errors::JIRA::WorklogTooShort => _error
          entry.status = :too_short
          entry.save
        end

        def update_worklog_and_update_entry
          worklog_id = update_worklog
          entry.status = :synced
          entry.jira_worklog_id = worklog_id
          entry.save
        rescue Errors::JIRA::WorklogTooShort => _error
          delete_previous_worklog
          entry.status = :too_short
          entry.save
        end

        def add_worklog
          username, password = jira_credentials
          Commands::JIRA::AddWorklog.run(
            entry.jira_issue_key,
            username,
            password,
            entry.toggl_duration,
            entry.toggl_started
          )
        end

        def update_worklog
          username, password = jira_credentials
          worklog_id = entry.history.last["jira_worklog_id"]
          Commands::JIRA::UpdateWorklog.run(
            entry.jira_issue_key,
            worklog_id,
            username,
            password,
            entry.toggl_duration,
            entry.toggl_started
          )
        end

        def delete_previous_worklog
          username, password = jira_credentials
          old_issue_key = entry.history.last["jira_issue_key"]
          old_worklog_id = entry.history.last["jira_worklog_id"]
          Commands::JIRA::DeleteWorklog.run(
            old_issue_key,
            old_worklog_id,
            username,
            password
          )
        end

        def jira_credentials
          user = Data::User.where(toggl_user: entry.toggl_user).first
          fail Errors::JIRA::UnknownUser, "No user for toggl_user=#{entry.toggl_user}" if user.nil?
          [user.jira_username, user.jira_password]
        end
      end
    end
  end
end
