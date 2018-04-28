# frozen_string_literal: true
require "data/stored_webhook"

# A set of helpers to simulate webhook requests
# easily, including headers specific to the service.
#
# ### Usage
#
# Include the module in your spec file:
#
#     include WebhooksHelpers
#
# When you want to simulate an incoming webhook (you need
# to have a file named `fixture_file` in the appropriate
# fixtures directory: `support/fixtures/stored_webhooks`).
#
#     receive_stored_webhook(:fixture_name)
#
# To add a webhook fixture, you may load a real webhook from the database
# (using `Data::StoredWebhook` records) and call `#write_to_fixture`).
#
# If you need to load a webhook fixture from the console (e.g. if you
# want to customize it):
#
#     webhook = JobTomate::Data::StoredWebhook.load_from_fixture(...)
#     receive_stored_webhook(webhook)
#
module WebhooksHelpers
  include RackTestHelpers

  GITHUB_HEADERS = {
    "CONTENT_TYPE" => "application/json",
    "USER_AGENT" => "GitHub-Hookshot/7a65dd9",
    "X-GitHub-Delivery" => "abdde180-f370-11e5-8c32-6da404003d66",
    "X-GitHub-Event" => ""
  }.freeze

  JIRA_HEADERS = {}.freeze
  IGNORED_HEADERS = %w(CONTENT_LENGTH).freeze

  # Simulate the specified webhook (by name - will fetch in
  # `support/fixtures/stored_webhooks` or `StoredWebhook`
  # instance directly.
  #
  # @param name_or_webhook [String or Data::StoredWebhook]
  # @param &block [Block] a block that enables rewriting the 
  #   `StoredWebhook` object before triggering it. Enables dynamically
  #   updating the payload or headers.
  def receive_stored_webhook(name_or_webhook, &block)
    webhook = webhook_from_name_or_webhook(name_or_webhook)
    verb = webhook.headers["REQUEST_METHOD"].downcase
    path = webhook.headers["REQUEST_PATH"]
    headers = webhook.headers.except(*IGNORED_HEADERS)
    headers_true_hash = {}.merge(headers)
    # Otherwise a BSON object, not handled correctly by Rack::Test#post

    # Dynamic update of the webhook
    yield(webhook) if block_given?

    send(verb, path, webhook.body, headers_true_hash)
  end

  def webhook_from_name_or_webhook(name_or_webhook)
    if name_or_webhook.is_a?(Symbol) || name_or_webhook.is_a?(String)
      return JobTomate::Data::StoredWebhook.load_from_fixture(name_or_webhook)
    end
    if name_or_webhook.is_a? JobTomate::Data::StoredWebhook
      return name_or_webhook
    end
    raise ArgumentError, "Argument must be String or StoredWebhook"
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

    if :issue_developer_backend.in?(override.keys)
      payload["issue"]["fields"]["customfield_10600"] = {
        "name" => override[:issue_developer_backend]
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

    if :issue_category.in?(override.keys)
      payload["issue"]["fields"]["customfield_10400"] = {
        "name" => override[:issue_category]
      }
    end

    headers = JIRA_HEADERS
    post "/webhooks/jira", payload.to_json, headers
  end
end
