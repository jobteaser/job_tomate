require 'uri'
require 'active_support/all'
require 'httparty'
require 'pry'

module JobTomate
  class JiraClient
    API_URL_PREFIX = 'https://jobteaser.atlassian.net/rest/api/2/issue/'
    API_PORT = 443
    DEFAULT_PARAMS = {}

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
    end
  end
end

