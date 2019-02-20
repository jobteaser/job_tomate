# frozen_string_literal: true

require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/stored_webhook"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  context "opened pull request related to JIRA issue" do

    [
      { project: "JobTeaser",
        branch_name: "jt-1234-create-crawler",
        issue_key: "jt-1234",
        webhook_name: "github_pull_request_opened_jira_jobteaser_related" },
      { project: "Career Services",
        branch_name: "cs-123-foo",
        issue_key: "cs-123",
        webhook_name: "github_pull_request_opened_jira_career_services_related" },
      { project: "Job Snow",
        branch_name: "js-1234-bar",
        issue_key: "js-1234",
        webhook_name: "github_pull_request_opened_jira_job_snow_related" },
      { project: "Sound School",
        branch_name: "sds-007-new-branch",
        issue_key: "sds-007",
        webhook_name: "github_pull_request_opened_jira_sds_related" }

    ].each do |jira_context|
        context "for project #{jira_context[:project]}" do

          it "adds a comment on the JIRA with the PR link" do
            expected_comment = "Opened PR: https://github.com/jobteaser/job_tomate/pull/3 - branch: #{jira_context[:branch_name]}"
            expected_body = "{\"body\":\"#{expected_comment}\"}"

            post_comment = stub_jira_request(:post, "/issue/#{jira_context[:issue_key]}/comment", expected_body)
            fill_jira_branch = stub_request(
              :put,
              "https://example.atlassian.net/rest/api/2/issue/#{jira_context[:issue_key]}?startAt=0"
              ).with(
                body: { fields: { customfield_12900: jira_context[:branch_name] } }.to_json,
                headers: {
                  "Authorization" => "Basic am9iX3RvbWF0ZV91c2VybmFtZTpqb2JfdG9tYXRlX3B3ZA==",
                  "Content-Type" => "application/json"
                }
              ).to_return(status: 200, body: "", headers: {})

              receive_stored_webhook(jira_context[:webhook_name])

            expect(post_comment).to have_been_requested
            expect(fill_jira_branch).to have_been_requested
          end

          it "sets the branch name field with the branch name" do
            expected_body = { fields: { customfield_12900: "jt-1234-create-crawler" } }.to_json

            fill_branch_name = stub_jira_request(:put, "/issue/jt-1234", expected_body)
            post_comment = stub_request(
              :post,
              "https://example.atlassian.net/rest/api/2/issue/jt-1234/comment?startAt=0"
            ).with(
              body: {
                body: "Opened PR: https://github.com/jobteaser/job_tomate/pull/3 - branch: jt-1234-create-crawler"
              }.to_json,
              headers: {
                "Authorization" => "Basic am9iX3RvbWF0ZV91c2VybmFtZTpqb2JfdG9tYXRlX3B3ZA==",
                "Content-Type" => "application/json"
              }
            ).to_return(status: 200, body: "", headers: {})

            receive_stored_webhook(:github_pull_request_opened_jira_jobteaser_related)

            expect(fill_branch_name).to have_been_requested
            expect(post_comment).to have_been_requested
          end
        end
    end
  end

  context "opened pull request not related to JIRA issue" do
    it "is successful and does nothing" do
      receive_stored_webhook(:github_pull_request_opened_not_jira_related)
      expect(last_response).to be_ok
    end
  end
end
