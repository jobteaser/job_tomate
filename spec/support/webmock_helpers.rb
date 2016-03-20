# Defines a set of helpers for stubbing specific types
# of requests.
module WebmockHelpers

  TOGGL_API_BASE_URL = "https://:api_token@toggl.com/reports/api/v2/details"
  TOGGL_BASE_PARAMS = "&user_agent=JobTomate&workspace_id=twid"

  RETURN_VALUES = {
    status: 200,
    body: "",
    headers: { "Content-Type" => "application/json" }
  }

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
  def stub_jira_request(verb, url_suffix, expected_request_body, response_body: "", username: "job_tomate_username", password: "job_tomate_pwd")
    url_prefix = ENV["JIRA_API_URL_PREFIX"].gsub("https://", "https://#{username}:#{password}@")
    stub_request(
      verb,
      "#{url_prefix}#{url_suffix}?startAt=0").
      with(
        body: expected_request_body,
        headers: { "Content-Type" => "application/json" }).
      to_return(RETURN_VALUES.merge(body: response_body))
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
      "icon_emoji" => ":japanese_ogre:"
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
      with( headers: { "Content-Type" => "application/json" }).
      to_return(RETURN_VALUES.merge(body: response_body))
  end
end
