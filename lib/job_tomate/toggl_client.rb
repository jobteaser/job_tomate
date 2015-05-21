require 'uri'
require 'active_support/all'
require 'httparty'
require 'pry'

module JobTomate
  class TogglClient
    API_URL = 'https://toggl.com/reports/api/v2/details'
    API_PORT = 443
    DEFAULT_PARAMS = {
      user_agent: 'JobTomate',
      workspace_id: ENV['TOGGL_WORKSPACE_ID']
    }

    def self.fetch_today_reports
      url = API_URL

      headers = {
        'Content-Type' => 'application/json'
      }

      params = DEFAULT_PARAMS.merge({
        page: 1
      })

      credentials = {
        username: ENV['TOGGL_API_TOKEN'],
        password: 'api_token'
      }

      response = HTTParty.get(url, {
        headers: headers,
        query: params,
        basic_auth: credentials
      })

      begin
        if response.code == 200 || response.code == 201
          reports = JSON.parse(response.body)
          binding.pry
        else
          logger.warn "Error (response code #{response.code}, content #{response.body})"
        end
      rescue => e
        # TODO fix this too large rescue
        logger.warn "Exception (#{e})"
      end
    end
  end
end

