require "job_tomate/commands/base"
require "job_tomate/commands/jira/support/client"

module JobTomate
  module Commands
    module Jira

      # Adds a worklog to the specified JIRA
      class AddWorklog < Base

        # @param issue_key [String]
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
        def run(issue_key, username, password, time_spent, start)
          return [:ok, nil] if handled_ignored_worklog(time_spent)

          body = {
            timeSpentSeconds: time_spent,
            started: format_date(start)
          }

          if ENV["DRY_RUN"] == "true"
            create_dry_run(issue_key, username, nil, body)
          else
            create(issue_key, username, password, body)
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
        def create_dry_run(_issue_key, _username, _password, _body)
          [:ok, rand(36**8).to_s(36)]
        end

        def create(issue_key, username, password, body)
          response = Client.exec_request(
            :post, "/issue/#{issue_key}/worklog",
            username, password,
            body
          )
          [:ok, response["id"]]
        end

        def format_date(date)
          date.strftime("%Y-%m-%dT%H:%M:%S.%3N%z")
        end
      end
    end
  end
end
