require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/stored_webhook"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  context "closed pull request merged related to JIRA issue" do
    it "is successful and does nothing" do
      receive_stored_webhook(:github_branch_created)
      expect(last_response).to be_ok
    end
  end
end
