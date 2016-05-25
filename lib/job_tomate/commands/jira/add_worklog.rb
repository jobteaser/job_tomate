require "commands/jira/support/client"
require "errors/jira"
require "support/service_pattern"

module JobTomate
  module Commands
    module JIRA

      # Adds a worklog to the specified JIRA
      class AddWorklog
        extend ServicePattern

        # @param issue_key [String]
        # @param username [String] JIRA username
        # @param password [String] JIRA password
        # @param time_spent [Integer] number of seconds of the worklog
        # @param start [Time]
        # @return [String] the ID of the worklog if correctly
        #   created.
        # @raise [Errors::JIRA::WorklogTooShort] if the worklog is too short
        #   to be sent to JIRA (< 1 min)
        # @raise [?] if some API error occurs
        def run(issue_key, username, password, time_spent, start)
          if handled_ignored_worklog(time_spent)
            fail Errors::JIRA::WorklogTooShort, "Ignored worklog < 1 min (not accepted by JIRA)"
          end
          body = {
            timeSpentSeconds: time_spent,
            started: format_time(start)
          }

          if ENV["JIRA_DRY_RUN"] == "true"
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
        def create_dry_run(issue_key, username, _password, body)
          rand(36**8).to_s(36)
        end

        def create(issue_key, username, password, body)
          response = Client.exec_request(
            :post, "/issue/#{issue_key}/worklog",
            username, password,
            body
          )
          response["id"]
        end

        # DUPLICATE update_worklog
        def format_time(time)
          time.in_time_zone("UTC").strftime("%Y-%m-%dT%H:%M:%S.%3N%z")
        end
      end
    end
  end
end
