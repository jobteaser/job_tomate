# Defines a set of helpers for stubbing specific types
# of requests.
module WebmockHelpers

  RETURN_VALUES = {
    status: 200,
    body: "",
    headers: {}
  }

  # @param verb [Symbol] e.g. :post
  # @param url [String]
  # @param return_values [Hash]
  #   by default: `status: 200, body: "", headers: {}`
  def stub_jira_request_as_job_tomate(verb, url, expected_body, return_values: RETURN_VALUES)
    stub_request(
      verb,
      url
    ).with(
      body: expected_body,
      headers: { "Content-Type" => "application/json" }
    ).to_return(return_values)
  end
end
