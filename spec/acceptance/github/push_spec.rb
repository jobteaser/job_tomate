require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/webhook_payload"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:request) do
    payload = Fixtures.webhook(:github, payload_name)
    post_webhook_github(:push, payload)
  end

  context "push created branch" do
    let(:payload_name) { :push_created }

    it "is successful and does nothing" do
      request
      expect(last_response).to be_ok
    end
  end

  context "push deleted branch" do
    let(:payload_name) { :push_deleted }

    it "is successful and does nothing" do
      request
      expect(last_response).to be_ok
    end
  end
end
