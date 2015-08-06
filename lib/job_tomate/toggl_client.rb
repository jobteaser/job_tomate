require 'uri'
require 'active_support/all'
require 'httparty'

module JobTomate
  class TogglClient
    API_URL = 'https://toggl.com/reports/api/v2/details'
    API_PORT = 443
    DEFAULT_PARAMS = {
      user_agent: 'JobTomate',
      workspace_id: ENV['TOGGL_WORKSPACE_ID']
    }

    # @param date_since [Date]
    # @param date_until [Date]
    def self.fetch_reports(date_since, date_until)
      page = 1
      all_results = []
      begin
        results = fetch_reports_page(
          date_since.strftime('%Y-%m-%d'),
          date_until.strftime('%Y-%m-%d'),
          page
        )['data']

        all_results += results
        page += 1
      end while(results.any?)
      all_results
    end

    def self.fetch_reports_page(date_since, date_until, page)
      url = API_URL

      headers = {
        'Content-Type' => 'application/json'
      }

      params = DEFAULT_PARAMS.merge({
        page: page,
        since: date_since,
        until: date_until
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
          JSON.parse(response.body)
        else
          LOGGER.warn "Error (response code #{response.code}, content #{response.body})"
        end
      rescue => e
        # TODO fix this too large rescue
        LOGGER.warn "Exception (#{e})"
      end
    end
  end
end
