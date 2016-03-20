# A set of helpers to simulate webhook requests
# easily, including headers specific to the service.
module WebhooksHelpers
  include RackTestHelpers

  GITHUB_HEADERS = {
    "CONTENT_TYPE" => "application/json",
    "USER_AGENT" => "GitHub-Hookshot/7a65dd9",
    "X-GitHub-Delivery" => "abdde180-f370-11e5-8c32-6da404003d66",
    "X-GitHub-Event" => ""
  }

  def post_webhook_github(event, payload)
    post "/webhooks/github", payload, GITHUB_HEADERS.merge(
      "X-GitHub-Event" => event.to_s
    )
  end

  def post_webhook_github_super(event, payload_name, override = {})
    # puts "2: " + payload_name.to_s
    # puts "2: " + override.to_s
    payload = JSON.parse Fixtures::GithubWebhooks.get(payload_name)
    if override[:pull_request_head_ref]
      payload["pull_request"]["head"]["ref"] = override[:pull_request_head_ref]
    end

    headers = GITHUB_HEADERS.merge(
      "X-GitHub-Event" => event.to_s
    )

    post "/webhooks/github", payload.to_json, headers
  end
end
