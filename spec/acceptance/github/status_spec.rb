require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/stored_webhook"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  context "status codeclimate no change" do
    it "is successful and does nothing" do
      receive_stored_webhook(:github_status_codeclimate_no_change)
      expect(last_response).to be_ok
    end
  end

  context "status circleci build successful" do
    it "is successful and does nothing" do
      receive_stored_webhook(:github_status_circleci_success)
      expect(last_response).to be_ok
    end
  end
end
