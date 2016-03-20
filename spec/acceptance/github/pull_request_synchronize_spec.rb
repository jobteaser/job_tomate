require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/webhook_payload"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:request) do
    post_webhook_github(:pull_request, payload)
  end

  let(:payload) do
    Fixtures.webhook(:github, :pull_request_synchronize)
  end

  it "is successful and does nothing" do
    request
    expect(last_response).to be_ok
  end
end
