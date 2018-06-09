# Defines a set of helpers for stubbing specific types
# of requests.
#
# `webmock_with_stored_request` is an helper that can be used
# in conjunction with `fixtures/stored_requests/<name>.yml` files.
# These files can be generated with `StoredRequest#write_to_fixture("<name>")`.
# You can then use these fixture files to mock requests using this helper.
# `spec/unit/jira/support/client_spec.rb` specs uses this approach.
module WebmockHelpers
  TOGGL_API_BASE_URL = "https://toggl.com/reports/api/v2/details"
  TOGGL_BASE_PARAMS = "&user_agent=JobTomate&workspace_id=twid"

  RETURN_VALUES = {
    status: 200,
    body: "",
    headers: { "Content-Type" => "application/json" }
  }

  # @param fixture_name [Symbol] name of the fixture, for example, for
  #   :get_issue, the corresponding file is `spec/support/fixtures/stored_requests/get_issue.yml`
  def webmock_with_stored_request(fixture_name)
    fixture = JobTomate::Data::StoredRequest.load_from_fixture(fixture_name)

    credentials = fixture[:request_options]["basic_auth"]
    if credentials.present?
      fixture.request_options["headers"]["Authorization"] = basic_auth_header(
        account: credentials["username"],
        password: credentials["password"]
      )
    end
    url = fixture.request_url
    url += "?#{fixture.request_options["query"].to_query}"

    stub_request(
      fixture.request_verb.to_sym,
      url).
      with(
        body: fixture.request_options["body"],
        headers: fixture.request_options["headers"]).
      to_return(
        status: fixture.response_status,
        headers: fixture.response_headers,
        body: fixture.response_body
      )
  end

  # @param verb [Symbol] e.g. :post
  # @param url_suffix [String]: will stub a request with url:
  #   #{ENV["JIRA_API_URL_PREFIX"]}#{url_suffix}?startAt=0
  # @param return_values [Hash]
  #   by default: `status: 200, body: "", headers: {}`
  #
  # Examples:
  #
  #     stub_jira_request(
  #       :post,
  #       "/issue/jt-1234/comment",
  #       expected_body
  #     )
  #
  def stub_jira_request(verb, url, expected_request_body, response_body: "", username: "job_tomate_username", password: "job_tomate_pwd")
    basic_auth_creds = { account: username, password: password }
    stub_request(
      verb,
      "#{ENV["JIRA_API_URL_PREFIX"]}#{url}?startAt=0").
      with(
        body: expected_request_body,
        headers: {
          "Authorization" => basic_auth_header(basic_auth_creds),
          "Content-Type" => "application/json"
        },
      ).to_return(RETURN_VALUES.merge(body: response_body))
  end

  def basic_auth_header(account:, password:)
    'Basic ' + ["#{account}:#{password}"].pack('m').delete("\r\n")
  end

  def stub_slack_request(expected_body, return_values: RETURN_VALUES)
    stub_request(
      :post,
      ENV["SLACK_WEBHOOK_URL"]
    ).with(
      body: expected_body,
      headers: { "Content-Type" => "application/json" }
    ).to_return(return_values)
  end

  def stub_slack_send_message_as_job_tomate(text, channel)
    body = {
      "text" => text,
      "channel" => channel,
      "username" => "JobTomate",
      "icon_emoji" => ":tomato:"
    }
    stub_slack_request(body.to_json)
  end

  # @param page [Int]
  # @param since_date_str [String]
  # @param until_date_str [String]
  def stub_toggl_api(page, since_date_str, until_date_str, response_body)
    stub_request(
      :get,
      "#{TOGGL_API_BASE_URL}?page=#{page}&since=#{since_date_str}&until=#{until_date_str}#{TOGGL_BASE_PARAMS}").
      with(
        headers: {
          "Authorization" => basic_auth_header(account: "", password: "api_token"),
          "Content-Type" => "application/json"
        }
      ).to_return(RETURN_VALUES.merge(body: response_body))
  end
end
