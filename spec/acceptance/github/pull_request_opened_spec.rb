require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/stored_webhook"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  context "opened pull request related to JIRA issue" do
    it "adds a comment on the JIRA with the PR link" do
      expected_comment = "Opened PR: https://github.com/jobteaser/job_tomate/pull/3 - branch: jt-1234-create-crawler"
      expected_body = "{\"body\":\"#{expected_comment}\"}"
      stub = stub_jira_request(
        :post,
        "/issue/jt-1234/comment",
        expected_body
      )
      receive_stored_webhook(:github_pull_request_opened_jira_related)
      expect(stub).to have_been_requested
    end
  end

  context "opened pull request not related to JIRA issue" do
    it "is successful and does nothing" do
      receive_stored_webhook(:github_pull_request_opened_not_jira_related)
      expect(last_response).to be_ok
    end
  end
end
