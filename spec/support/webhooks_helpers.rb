require "data/stored_webhook"

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
  IGNORED_HEADERS = %w(CONTENT_LENGTH)

  def receive_stored_webhook(name)
    webhook = JobTomate::Data::StoredWebhook.load_from_fixture(name)
    verb = webhook.headers["REQUEST_METHOD"].downcase
    path = webhook.headers["REQUEST_PATH"]
    headers = webhook.headers.except(*IGNORED_HEADERS)
    headers_true_hash = {}.merge(headers)
    # Otherwise a BSON object, not handled correctly by Rack::Test#post
    send(verb, path, webhook.body, headers_true_hash)
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
