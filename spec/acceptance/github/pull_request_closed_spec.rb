require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/stored_webhook"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  context "closed pull request merged related to JIRA issue" do
    it "adds a comment on the JIRA with the PR link" do
      expected_body = "{\"body\":\"Merged PR in develop: https://github.com/jobteaser/job_tomate/pull/3\"}"

      post_comment = stub_jira_request(:post, "/issue/jt-1234/comment", expected_body)

      receive_stored_webhook(:github_pull_request_closed_merged_jira_jobteaser_related)

      expect(post_comment).to have_been_requested
    end

    context "in the career services JIRA project" do
      it "adds a comment on the JIRA with the PR link" do
        expected_body = "{\"body\":\"Merged PR in develop: https://github.com/jobteaser/job_tomate/pull/3\"}"

        post_comment = stub_jira_request(:post, "/issue/cs-123/comment", expected_body)

        receive_stored_webhook(:github_pull_request_closed_merged_jira_career_services_related)

        expect(post_comment).to have_been_requested
      end
    end

    context "in the Job Snow JIRA project" do
      it "adds a comment on the JIRA with the PR link" do
        expected_body = "{\"body\":\"Merged PR in develop: https://github.com/jobteaser/job_tomate/pull/3\"}"

        post_comment = stub_jira_request(:post, "/issue/js-1234/comment", expected_body)

        receive_stored_webhook(:github_pull_request_closed_merged_jira_job_snow_related)

        expect(post_comment).to have_been_requested
      end
    end

    context "in the Sound School JIRA project" do
      it "adds a comment on the JIRA with the PR link" do
        expected_body = "{\"body\":\"Merged PR in develop: https://github.com/jobteaser/job_tomate/pull/3\"}"

        post_comment = stub_jira_request(:post, "/issue/sds-1234/comment", expected_body)

        receive_stored_webhook(:github_pull_request_closed_merged_jira_sds_related)

        expect(post_comment).to have_been_requested
      end
    end
  end

  context "closed pull request not merged related to JIRA issue" do
    it "adds a comment on the JIRA with the PR link" do
      expected_body = "{\"body\":\"Closed PR without merging: https://github.com/jobteaser/job_tomate/pull/3\"}"
      stub = stub_jira_request(:post, "/issue/jt-1234/comment",
        expected_body
      )
      receive_stored_webhook(:github_pull_request_closed_not_merged_jira_jobteaser_related)
      expect(stub).to have_been_requested
    end

    context "in the career services JIRA project" do
      it "adds a comment on the JIRA with the PR link" do
        expected_body = "{\"body\":\"Closed PR without merging: https://github.com/jobteaser/job_tomate/pull/3\"}"
        stub = stub_jira_request(:post, "/issue/cs-123/comment",
          expected_body
        )
        receive_stored_webhook(:github_pull_request_closed_not_merged_jira_career_services_related)
        expect(stub).to have_been_requested
      end
    end

    context "in the Job Snow JIRA project" do
      it "adds a comment on the JIRA with the PR link" do
        expected_body = "{\"body\":\"Closed PR without merging: https://github.com/jobteaser/job_tomate/pull/3\"}"
        stub = stub_jira_request(:post, "/issue/js-1234/comment",
          expected_body
        )
        receive_stored_webhook(:github_pull_request_closed_not_merged_jira_job_snow_related)
        expect(stub).to have_been_requested
      end
    end

    context "in the Sound School JIRA project" do
      it "adds a comment on the JIRA with the PR link" do
        expected_body = "{\"body\":\"Closed PR without merging: https://github.com/jobteaser/job_tomate/pull/3\"}"
        stub = stub_jira_request(:post, "/issue/sds-1234/comment",
          expected_body
        )
        receive_stored_webhook(:github_pull_request_closed_not_merged_jira_sds_related)
        expect(stub).to have_been_requested
      end
    end
  end

  context "closed pull request merged not related to JIRA issue" do

    # NB: would fail if a JIRA request was done since it is not mocked.
    it "stores the webhook and does nothing else" do
      expect { receive_stored_webhook(:github_pull_request_closed_merged_not_jira_related) }.
        to change { JobTomate::Data::StoredWebhook.count }.
        by(1)
    end
  end
end
