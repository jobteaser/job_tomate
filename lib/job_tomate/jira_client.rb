require 'uri'
require 'active_support/all'
require 'httparty'
require 'pry'

module JobTomate
  class JiraClient
    API_URL = 'https://jobteaser.atlassian.net/rest/api/2/issue/JT-2253/worklog'
    API_PORT = 443
    DEFAULT_PARAMS = {
    }

    def self.add_worklog()
      url = API_URL

      headers = {
        'Content-Type' => 'application/json'
      }

      params = DEFAULT_PARAMS.merge({
      })

      credentials = {
        username: "romain.champourlier",
        password: "j+zGVNpW44jvXbJe@6Kr"
      }

      body = {
        timeSpentSeconds: 3600
      }

      response = HTTParty.post(url, {
        headers: headers,
        query: params,
        basic_auth: credentials,
        body: body.to_json
      })

      begin
        if response.code == 200 || response.code == 201
          JSON.parse(response.body)
        else
          puts "Error (response code #{response.code}, content #{response.body})"
        end
      rescue => e
        # TODO fix this too large rescue
        puts "Exception (#{e})"
      end
    end
  end
end

