# frozen_string_literal: true

require "job_tomate/commands/jira/support/client"
require "support/service_pattern"

module JobTomate
  module Commands
    module JIRA

      # Update an existing JIRA issue worklog
      class UpdateWorklog
        extend ServicePattern

        # @param issue_key [String] JIRA issue key
        # @param worklog_id [String] JIRA worklog ID
        # @param username [String] JIRA username
        # @param password [String] JIRA password
        # @param time_spent [Integer] number of seconds of the worklog
        # @param start [Time]
        # @param comment [String] optional, defaults to nil (comment unchanged,
        #   to clear the comment, use `''`)
        # @return [String] ID of the updated worklog
        # @raise [Errors::JIRA::WorklogTooShort] if the worklog is too short
        #   to be sent to JIRA (< 1 min)
        # @raise [?] if some error occured with the API
        def run(issue_key, worklog_id, username, password, time_spent, start, comment = nil)
          if handled_ignored_worklog(time_spent)
            raise Errors::JIRA::WorklogTooShort, "Ignored worklog < 1 min (not accepted by JIRA)"
          end

          body = {
            timeSpentSeconds: time_spent,
            started: format_time(start)
          }
          body[:comment] = comment unless comment.nil?

          do_update(issue_key, worklog_id, username, password, body)
        end

        private

        def do_update(issue_key, worklog_id, username, password, body)
          if ENV["JIRA_DRY_RUN"] == "true"
            return update_dry_run(issue_key, worklog_id, username, nil, body)
          end
          update(issue_key, worklog_id, username, password, body)
        end

        def handled_ignored_worklog(time_spent)
          return false if time_spent.to_i >= 60
          LOGGER.info "Ignored worklog < 1 min (not accepted by JIRA)"
          true
        end

        # Returns a random 8-char string to fake a JIRA
        # worklog ID.
        def update_dry_run(_issue_key, worklog_id, _username, _password, _body)
          worklog_id
        end

        def update(issue_key, worklog_id, username, password, body)
          response = Client.exec_request(
            :put, "/issue/#{issue_key}/worklog/#{worklog_id}",
            username, password,
            body
          )
          response["id"]
        end

        # DUPLICATE add_worklog
        def format_time(time)
          time.in_time_zone("UTC").strftime("%Y-%m-%dT%H:%M:%S.%3N%z")
        end
      end
    end
  end
end
