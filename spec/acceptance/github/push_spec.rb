require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/stored_webhook"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  context "push created branch" do
    it "is successful and does nothing" do
      receive_stored_webhook(:github_push_created_branch)
      expect(last_response).to be_ok
    end
  end

  context "push deleted branch" do
    it "is successful and does nothing" do
      receive_stored_webhook(:github_push_deleted_branch)
      expect(last_response).to be_ok
    end
  end
end
