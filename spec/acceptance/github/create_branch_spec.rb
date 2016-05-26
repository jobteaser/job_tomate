require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/stored_webhook"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:request) do
    post_webhook_github(:create, payload)
  end

  let(:payload) do
    Fixtures.webhook(:github, :create_branch)
  end

  it "is successful and does nothing" do
    request
    expect(last_response).to be_ok
  end
end
