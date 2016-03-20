require "job_tomate/commands/base"
require "job_tomate/commands/jira/support/client"

module JobTomate
  module Commands
    module Jira

      # Update an existing JIRA issue worklog
      class UpdateWorklog < Base

        # @param issue_key [String] JIRA issue key
        # @param worklog_id [String] JIRA worklog ID
        # @param username [String] JIRA username
        # @param password [String] JIRA password
        # @param time_spent [Integer] number of seconds of the worklog
        # @param start [Time]
        # @return [Array] 2-item array representing the status of
        #   the response:
        #     - [:ok, nil] if everything went well but the worklog
        #       was not created (not long enough)
        #     - [:ok, <id>] if the worklog was created, <id> is the
        #       JIRA worklog ID
        #     - [:error, nil] if the creation failed (e.g. API error...)
        def run(issue_key, worklog_id, username, password, time_spent, start)
          return [:ok, nil] if handled_ignored_worklog(time_spent)

          body = {
            timeSpentSeconds: time_spent,
            started: format_date(start)
          }

          if ENV["DRY_RUN"] == "true"
            update_dry_run(issue_key, worklog_id, username, nil, body)
          else
            update(issue_key, worklog_id, username, password, body)
          end
        end

        private

        def handled_ignored_worklog(time_spent)
          return false if time_spent.to_i >= 60
          LOGGER.info "Ignored worklog < 1 min (not accepted by JIRA)"
          true
        end

        # Returns a random 8-char string to fake a JIRA
        # worklog ID.
        def update_dry_run(issue_key, worklog_id, username, _password, body)
          LOGGER.info log_update_message(issue_key, worklog_id, username, body)
          [:ok, worklog_id]
        end

        def update(issue_key, worklog_id, username, password, body)
          response = Client.exec_request(
            :put, "/issue/#{issue_key}/worklog/#{worklog_id}",
            username, password,
            body
          )
          LOGGER.info log_update_message(issue_key, worklog_id, username, body)
          [:ok, response["id"]]
        end

        def log_update_message(issue_key, worklog_id, username, body)
          msg = "Updated worklog #{worklog_id} for #{issue_key} with body #{body} (via #{username})"
          ENV["DRY_RUN"] ? "#{msg} -- SKIPPED" : msg
        end

        def format_date(date)
          date.strftime("%Y-%m-%dT%H:%M:%S.%3N%z")
        end
      end
    end
  end
end
