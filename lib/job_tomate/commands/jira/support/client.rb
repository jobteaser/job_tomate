require "uri"
require "active_support/all"
require "httparty"

module JobTomate
  module Commands
    module JIRA

      # A JIRA client encapsulating the request logic:
      #   - performing the request,
      #   - processing the response,
      #   - in case of a paginated response, fetching
      #     all results and aggregating them.
      module Client
        API_URL_PREFIX = ENV["JIRA_API_URL_PREFIX"]
        API_PORT = 443
        DEFAULT_PARAMS = {}

        def exec_request(verb, url_suffix, username, password, body, params = {})
          merged_response = {}
          start_at = 0
          loop do
            merged_response = merge_paginated_responses(
              merged_response,
              exec_request_base(verb, url_suffix, username, password, body, params.merge("startAt" => start_at))
            )
            return merged_response if verb != :get
            return merged_response if merged_response["total"].nil?
            if merged_response["total"] <= merged_response["startAt"] + merged_response["maxResults"]
              return merged_response
            end
            start_at += merged_response["maxResults"]
          end
        end
        module_function :exec_request

        # If new response doesn't have the pagination keys we assume
        # there is no merge to do, the response is not a paginated
        # one.
        def merge_paginated_responses(merged_response, new_response)
          fail "JIRA API error (#{new_response['errorMessages']})" if new_response["errorMessages"].present?

          return merged_response if new_response.nil? # e.g. nil on DELETE success

          pagination_keys = %w(startAt total maxResults)
          return new_response if new_response.slice(*pagination_keys).empty?

          merged_response = merged_response.merge(new_response.slice(*pagination_keys))
          (new_response.keys - pagination_keys).each do |key|
            if new_response[key].is_a?(Array)
              merged_response[key] ||= []
              merged_response[key] += new_response[key]
            end
          end
          merged_response
        end
        module_function :merge_paginated_responses

        def exec_request_base(verb, url_suffix, username, password, body, params = {})
          url = "#{API_URL_PREFIX}#{url_suffix}"

          headers = {
            "Content-Type" => "application/json"
          }

          final_params = DEFAULT_PARAMS.merge(params)

          credentials = {
            username: username,
            password: password
          }

          JobTomate::LOGGER.info "[JIRA] #{verb.upcase} #{url} #{headers} #{final_params} #{body}"
          response = HTTParty.send(
            verb, url,
            headers: headers,
            query: final_params,
            basic_auth: credentials,
            body: body.present? ? body.to_json : nil
          )
          response
        end
        module_function :exec_request_base

        def handle_response(response)
          if response.code != 200 && response.code != 201 && response.code != 204
            fail "Error (response code #{response.code}, content #{response.body})"
          end
          response
        end
        module_function :handle_response
      end
    end
  end
end
