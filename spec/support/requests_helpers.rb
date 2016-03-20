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

  JIRA_HEADERS = {}

  # TODO: remove
  def post_webhook_github(event, payload)
    post "/webhooks/github", payload, GITHUB_HEADERS.merge(
      "X-GitHub-Event" => event.to_s
    )
  end

  # TODO: rename to post_webhook_github
  def post_webhook_github_super(event, payload_name, override = {})
    payload = JSON.parse Fixtures.webhook(:github, payload_name)
    if override[:pull_request_head_ref]
      payload["pull_request"]["head"]["ref"] = override[:pull_request_head_ref]
    end

    headers = GITHUB_HEADERS.merge(
      "X-GitHub-Event" => event.to_s
    )

    post "/webhooks/github", payload.to_json, headers
  end

  def post_webhook_jira(payload_name, override = {})
    payload = JSON.parse Fixtures.webhook(:jira, payload_name)

    if :comment_body.in?(override.keys)
      payload["comment"]["body"] = override[:comment_body]
    end

    if :issue_assignee.in?(override.keys)
      payload["issue"]["fields"]["assignee"] = {
        "name" => override[:issue_assignee]
      }
    end

    if :issue_developer.in?(override.keys)
      payload["issue"]["fields"]["customfield_10600"] = {
        "name" => override[:issue_developer]
      }
    end

    if :issue_reviewer.in?(override.keys)
      payload["issue"]["fields"]["customfield_10601"] = {
        "name" => override[:issue_reviewer]
      }
    end

    if :issue_feature_owner.in?(override.keys)
      payload["issue"]["fields"]["customfield_11200"] = {
        "name" => override[:issue_feature_owner]
      }
    end

    if :issue_status.in?(override.keys)
      payload["issue"]["fields"]["status"] = {
        "name" => override[:issue_status]
      }
    end

    if :issue_priority.in?(override.keys)
      payload["issue"]["fields"]["priority"] = {
        "name" => override[:issue_priority]
      }
    end

    if :issue_category.in?(override.keys)
      payload["issue"]["fields"]["customfield_10400"] = {
        "name" => override[:issue_category]
      }
    end

    headers = JIRA_HEADERS
    post "/webhooks/jira", payload.to_json, headers
  end
end
