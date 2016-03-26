require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/webhook_payload"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:request) do
    post_webhook_github(:push, payload)
  end

  let(:payload) do
    Fixtures::GithubWebhooks.get(:push)
  end

  it "is successful" do
    request
    expect(last_response).to be_ok
  end
end
