require 'uri'
require 'active_support/all'
require 'httparty'

module JobTomate
  class JiraClient
    API_URL_PREFIX = 'https://jobteaser.atlassian.net/rest/api/2/issue/'
    API_PORT = 443
    DEFAULT_PARAMS = {}

    def self.make_transition(issue_key, username, password, status_id)
      url = "#{API_URL_PREFIX}#{issue_key}/transitions"

      headers = {
        'Content-Type' => 'application/json'
      }

      params = DEFAULT_PARAMS.merge({
      })

      credentials = {
        username: username,
        password: password
      }

      body = {
        transition: {id: "121"}
      }

# CHANGE PLEAAAAAAAAASEEEEEEEEEE  DSKDLMSQKLDMSQKDLSQMKAZOPEIZAOPEIZA

      if ENV['APP_ENV'] == "development"
        response = HTTParty.put(url, {
          headers: headers,
          query: params,
          basic_auth: credentials,
          body: body.to_json
        })

        begin
          LOGGER.info "Made transition of #{issue_key}"
          if response.code == 200 || response.code == 201 || response.code == 204
            JSON.parse(response.body)
            true
          else
            LOGGER.warn "Error (response code #{response.code}, content #{response.body})"
            false
          end
        rescue => e
          # TODO fix this too large rescue
          LOGGER.warn "Exception (#{e})"
          false
        end
      else
        LOGGER.info "made transition of #{issue_key} - SKIPPED BECAUSE IN DEV"
        return true
      end
    end

    def self.assign_user(issue_key, username, password, assignee)
      url = "#{API_URL_PREFIX}#{issue_key}/"

      headers = {
        'Content-Type' => 'application/json'
      }

      params = DEFAULT_PARAMS.merge({
      })

      credentials = {
        username: username,
        password: password
      }

      body = {
        fields: {assignee: {name: assignee}}
      }

      if ENV['APP_ENV'] != "development"
        response = HTTParty.put(url, {
          headers: headers,
          query: params,
          basic_auth: credentials,
          body: body.to_json
        })

        begin
          LOGGER.info "Assigned user (#{assignee}) to #{issue_key}"
          if response.code == 200 || response.code == 201 || response.code == 204
            JSON.parse(response.body)
            true
          else
            LOGGER.warn "Error (response code #{response.code}, content #{response.body})"
            false
          end
        rescue => e
          # TODO fix this too large rescue
          LOGGER.warn "Exception (#{e})"
          false
        end
      else
        LOGGER.info "assigned user (#{assignee}) to #{issue_key} - SKIPPED BECAUSE IN DEV"
        return true
      end
    end

    def self.add_comment(issue_key, username, password, comment)
      url = "#{API_URL_PREFIX}#{issue_key}/comment"

      headers = {
        'Content-Type' => 'application/json'
      }

      params = DEFAULT_PARAMS.merge({
      })

      credentials = {
        username: username,
        password: password
      }

      body = {
        body: comment
      }

      if ENV['APP_ENV'] != "development"
        response = HTTParty.post(url, {
          headers: headers,
          query: params,
          basic_auth: credentials,
          body: body.to_json
        })

        begin
          LOGGER.info "Add comment (#{comment}) to #{issue_key} as #{username}"
          if response.code == 200 || response.code == 201
            JSON.parse(response.body)
            true
          else
            LOGGER.warn "Error (response code #{response.code}, content #{response.body})"
            false
          end
        rescue => e
          # TODO fix this too large rescue
          LOGGER.warn "Exception (#{e})"
          false
        end
      else
        LOGGER.info "Add comment (#{comment}) to #{issue_key} as #{username} - SKIPPED BECAUSE IN DEV"
        return true
      end
    end

    # @return [Boolean] true if successful, false otherwise
    def self.add_worklog(issue_key, username, password, time_spent)
      url = "#{API_URL_PREFIX}#{issue_key}/worklog"

      headers = {
        'Content-Type' => 'application/json'
      }

      params = DEFAULT_PARAMS.merge({
      })

      credentials = {
        username: username,
        password: password
      }

      body = {
        timeSpentSeconds: time_spent
      }

      if ENV['APP_ENV'] != "development"
        response = HTTParty.post(url, {
          headers: headers,
          query: params,
          basic_auth: credentials,
          body: body.to_json
        })

        begin
          LOGGER.info "Add worklog (#{time_spent}s) to #{issue_key} as #{username}"
          if response.code == 200 || response.code == 201
            JSON.parse(response.body)
            true
          else
            LOGGER.warn "Error (response code #{response.code}, content #{response.body})"
            false
          end
        rescue => e
          # TODO fix this too large rescue
          LOGGER.warn "Exception (#{e})"
          false
        end
      else
        LOGGER.info "Add worklog (#{time_spent}s) to #{issue_key} as #{username} - SKIPPED BECAUSE IN DEV"
        return true
      end
    end
  end
end

