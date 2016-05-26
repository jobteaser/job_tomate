require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/stored_webhook"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:request) do
    post_webhook_github(:status, payload)
  end

  context "Coveralls success" do
    let(:payload) do
      Fixtures.webhook(:github, :status_coveralls_success)
    end

    it "is successful and does nothing" do
      request
      expect(last_response).to be_ok
    end
  end

  context "TravisCI build in progress" do
    let(:payload) do
      Fixtures.webhook(:github, :status_travis_build_in_progress)
    end

    it "is successful and does nothing" do
      request
      expect(last_response).to be_ok
    end
  end
end
