require 'uri'
require 'active_support/all'
require 'httparty'

module JobTomate
  module Output

    # A client for JIRA for:
    #   - setting people on issues
    #   - adding worklogs
    #   - adding comments
    class JiraClient
      API_URL_PREFIX = 'https://jobteaser.atlassian.net/rest/api/2'
      API_PORT = 443
      DEFAULT_PARAMS = {}

      # Sets the people associated to the issue: assignee, developer,
      # reviewer.
      def self.set_people(issue_key, username, password, assignee, developer, reviewer)
        body = {
          fields: {
            assignee:           { name: assignee },
            customfield_10600:  { name: developer },
            customfield_10601:  { name: reviewer }
          }
        }

        if ENV['APP_ENV'] != 'development'
          response = exec_request(:put, "/issue/#{issue_key}/", username, password, body)
          handle_response(response, "assigned user (#{assignee}) to #{issue_key}")
        else
          LOGGER.info "Assigned user (#{assignee}) to #{issue_key} - SKIPPED BECAUSE IN DEV"
          return true
        end
      end

      def self.add_comment(issue_key, username, password, comment)
        body = {
          body: comment
        }

        log_message = "Add comment (#{comment}) to #{issue_key} as #{username}"
        if ENV['APP_ENV'] != 'development'
          response = exec_request(:post, "/issue/#{issue_key}/comment", username, password, body)
          handle_response(response, log_message)
        else
          LOGGER.info "#{log_message} - SKIPPED BECAUSE IN DEV"
          return true
        end
      end

      def self.add_worklog(issue_key, username, password, time_spent, start)
        if time_spent.to_i < 60
          LOGGER.info 'Skipping worklog < 1 min (not accepted by JIRA)'
          return true
        end

        body = {
          timeSpentSeconds: time_spent,
          started: start
        }

        if ENV['APP_ENV'] != 'development'
          response = exec_request(:post, "/issue/#{issue_key}/worklog", username, password, body)
          handle_response(response, "Add worklog (#{time_spent}s) to #{issue_key} as #{username}. Started at #{start}")
        else
          LOGGER.info "Add worklog (#{time_spent}s) to #{issue_key} as #{username}. Started at #{start} - SKIPPED BECAUSE IN DEV"
          return true
        end
      end

      # IMPLEMENTATION

      def self.exec_request(verb, url_suffix, username, password, body, params = {})
        url = "#{API_URL_PREFIX}#{url_suffix}"

        headers = {
          'Content-Type' => 'application/json'
        }

        final_params = DEFAULT_PARAMS.merge(params)

        credentials = {
          username: username,
          password: password
        }

        HTTParty.send(verb, url, {
          headers: headers,
          query: final_params,
          basic_auth: credentials,
          body: body.to_json
        })
      end

      def self.handle_response(response, success_message)
        LOGGER.info success_message
        if response.code == 200 || response.code == 201 || response.code == 204
          true
        else
          LOGGER.error "Error (response code #{response.code}, content #{response.body})"
          false
        end
      end
    end
  end
end
