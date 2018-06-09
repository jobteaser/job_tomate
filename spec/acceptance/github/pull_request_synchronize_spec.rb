# frozen_string_literal: true

require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/stored_webhook"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  context "opened pull request not related to JIRA issue" do
    it "is successful and does nothing" do
      receive_stored_webhook(:github_pull_request_synchronize)
      expect(last_response).to be_ok
    end
  end
end
