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

        def delete_dry_run(_issue_key, worklog_id, _username, _password)
          [:ok, worklog_id]
        end

        def delete(issue_key, worklog_id, username, password)
          response = Client.exec_request(
            :delete, "/issue/#{issue_key}/worklog/#{worklog_id}",
            username, password,
            {}
          )
          [:ok, response["id"]]
        end
      end
    end
  end
end
