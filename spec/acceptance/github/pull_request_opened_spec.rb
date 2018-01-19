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

      post_comment = stub_jira_request(:post, "/issue/jt-1234/comment", expected_body)
      fill_jira_branch = stub_request(
        :put,
        "https://example.atlassian.net/rest/api/2/issue/jt-1234?startAt=0"
        ).with(
          body: "{\"fields\":{\"Branch Name\":\"jt-1234-create-crawler\"}}",
          headers: {
            'Authorization'=>'Basic am9iX3RvbWF0ZV91c2VybmFtZTpqb2JfdG9tYXRlX3B3ZA==',
            'Content-Type'=>'application/json'
          }
        ).to_return(status: 200, body: "", headers: {})

      receive_stored_webhook(:github_pull_request_opened_jira_jobteaser_related)

      expect(post_comment).to have_been_requested
      expect(fill_jira_branch).to have_been_requested
    end

    it "sets the branch name field with the branch name" do
      expected_body = "{\"fields\":{\"Branch Name\":\"jt-1234-create-crawler\"}}"

      fill_branch_name = stub_jira_request(:put, "/issue/jt-1234", expected_body)
      post_comment = stub_request(
        :post,
        "https://example.atlassian.net/rest/api/2/issue/jt-1234/comment?startAt=0"
      ).with(
        body: "{\"body\":\"Opened PR: https://github.com/jobteaser/job_tomate/pull/3 - branch: jt-1234-create-crawler\"}",
        headers: {'Authorization'=>'Basic am9iX3RvbWF0ZV91c2VybmFtZTpqb2JfdG9tYXRlX3B3ZA==', 'Content-Type'=>'application/json'}
      ).to_return(status: 200, body: "", headers: {})

      receive_stored_webhook(:github_pull_request_opened_jira_jobteaser_related)

      expect(fill_branch_name).to have_been_requested
      expect(post_comment).to have_been_requested
    end

    context "on the Career Services project" do
      it "adds a comment on the JIRA with the PR link" do
        expected_comment = "Opened PR: https://github.com/jobteaser/job_tomate/pull/3 - branch: cs-123-foo"
        expected_body = "{\"body\":\"#{expected_comment}\"}"

        post_comment = stub_jira_request(:post, "/issue/cs-123/comment", expected_body)
        fill_jira_branch = stub_request(
          :put,
          "https://example.atlassian.net/rest/api/2/issue/cs-123?startAt=0"
          ).with(
            body: "{\"fields\":{\"Branch Name\":\"cs-123-foo\"}}",
            headers: {
              'Authorization'=>'Basic am9iX3RvbWF0ZV91c2VybmFtZTpqb2JfdG9tYXRlX3B3ZA==',
              'Content-Type'=>'application/json'
            }
          ).to_return(status: 200, body: "", headers: {})

        receive_stored_webhook(:github_pull_request_opened_jira_career_services_related)

        expect(post_comment).to have_been_requested
        expect(fill_jira_branch).to have_been_requested
      end

      it "sets the branch name field with the branch name" do
        expected_body = "{\"fields\":{\"Branch Name\":\"cs-123-foo\"}}"

        fill_branch_name = stub_jira_request(:put, "/issue/cs-123", expected_body)
        post_comment = stub_request(
          :post,
          "https://example.atlassian.net/rest/api/2/issue/cs-123/comment?startAt=0"
        ).with(
          body: "{\"body\":\"Opened PR: https://github.com/jobteaser/job_tomate/pull/3 - branch: cs-123-foo\"}",
          headers: {
            'Authorization'=>'Basic am9iX3RvbWF0ZV91c2VybmFtZTpqb2JfdG9tYXRlX3B3ZA==',
            'Content-Type'=>'application/json'
          }
        ).to_return(status: 200, body: "", headers: {})

        receive_stored_webhook(:github_pull_request_opened_jira_career_services_related)

        expect(fill_branch_name).to have_been_requested
        expect(post_comment).to have_been_requested
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
