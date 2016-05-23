require "job_tomate/commands/jira/support/client"
require "support/service_pattern"

module JobTomate
  module Commands
    module JIRA

      # Adds a worklog to the specified JIRA
      class DeleteWorklog
        extend ServicePattern

        # @param issue_key [String]
        # @param worklog_id [String]
        # @param username [String]
        # @param password [String]
        # @return [String] deleted worklog ID
        def run(issue_key, worklog_id, username, password)
          if ENV["JIRA_DRY_RUN"] == "true"
            delete_dry_run(issue_key, worklog_id, username, nil)
          else
            delete(issue_key, worklog_id, username, password)
          end
        end

        private

        def delete_dry_run(_issue_key, worklog_id, _username, _password)
          worklog_id
        end

        def delete(issue_key, worklog_id, username, password)
          response = Client.exec_request(
            :delete, "/issue/#{issue_key}/worklog/#{worklog_id}",
            username, password,
            nil
          )
          response["id"]
        end
      end
    end
  end
end
