require 'uri'
require 'active_support/all'
require 'httparty'

# TODO: use TogglCache::Client instead
module JobTomate
  module Commands
    module Toggl

      # Toggl client wrapper
      class Client
        API_URL = 'https://toggl.com/reports/api/v2/'
        API_SUFFIX_DETAILS = 'details'
        API_SUFFIX_SUMMARY = 'summary'

        API_PORT = 443
        DEFAULT_PARAMS = {
          user_agent: 'JobTomate',
          workspace_id: ENV['TOGGL_WORKSPACE_ID']
        }

        # @param options [Hash]: Toggl API options
        def self.fetch_reports_multiple_pages(options)
          page = 1
          all_results = []
          loop do
            results = fetch_reports_details(options.merge(page: page))['data']
            all_results += results
            page += 1
            puts results
            break if results.empty?
          end
          all_results
        end

        def self.fetch_reports_details(options)
          fetch_reports_raw(API_URL + API_SUFFIX_DETAILS, options)
        end

        def self.fetch_reports_summary(options)
          fetch_reports_raw(API_URL + API_SUFFIX_SUMMARY, options)
        end

        # @param options [Hash]: Toggl API options
        def self.fetch_reports_raw(url, options)
          headers = {
            'Content-Type' => 'application/json'
          }

          params = DEFAULT_PARAMS.merge(options)

          credentials = {
            username: ENV['TOGGL_API_TOKEN'],
            password: 'api_token'
          }

          response = HTTParty.get(url,
            headers: headers,
            query: params,
            basic_auth: credentials
          )

          begin
            if response.code == 200 || response.code == 201
              JSON.parse(response.body)
            else
              LOGGER.error "Error (response code #{response.code}, content #{response.body})"
            end
          rescue => e
            # TODO: fix this too large rescue
            LOGGER.error "Exception (#{e})"
          end
        end
      end
    end
  end
end
