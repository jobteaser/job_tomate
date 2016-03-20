require "job_tomate/commands/jira/support/client"

module JobTomate
  module Commands
    module Jira

      # Adds a worklog to the specified JIRA
      class DeleteWorklog < Base
        def run(issue_key, worklog_id, username, password)
          if ENV["DRY_RUN"] == "true"
            delete_dry_run(issue_key, worklog_id, username, nil)
          else
            delete(issue_key, worklog_id, username, password)
          end
        end

        private

        def delete_dry_run(issue_key, worklog_id, username, _password)
          LOGGER.info log_delete_message(issue_key, worklog_id, username)
          [:ok, worklog_id]
        end

        def delete(issue_key, worklog_id, username, password)
          LOGGER.info log_delete_message(issue_key, worklog_id, username)
          response = Client.exec_request(
            :delete, "/issue/#{issue_key}/worklog/#{worklog_id}",
            username, password,
            {}
          )
          [:ok, response["id"]]
        end

        def log_delete_message(issue_key, worklog_id, username)
          msg = "Deleted worklog #{worklog_id} for #{issue_key} (via #{username})"
          ENV["DRY_RUN"] ? "#{msg} -- SKIPPED" : msg
        end
      end
    end
  end
end
