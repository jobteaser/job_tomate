require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/webhook_payload"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:request) do
    post_webhook_github(:status, payload)
  end

  context "Coveralls success" do
    let(:payload) do
      Fixtures::GithubWebhooks.get(:status_coveralls_success)
    end

    it "is successful" do
      request
      expect(last_response).to be_ok
    end
  end

  context "TravisCI build in progress" do
    let(:payload) do
      Fixtures::GithubWebhooks.get(:status_travis_build_in_progress)
    end

    it "is successful" do
      request
      expect(last_response).to be_ok
    end
  end
end
