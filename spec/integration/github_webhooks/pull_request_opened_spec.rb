require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/webhook_payload"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:request) do
    post_webhook_github(:pull_request, payload)
  end

  context "opened pull request" do
    let(:base_payload) do
      Fixtures::GithubWebhooks.get(:pull_request_opened)
    end
    let(:payload) { base_payload }

    it "is successful" do
      request
      expect(last_response).to be_ok
    end

    it "stores the payload" do
      expect { request }.
        to change { JobTomate::Data::WebhookPayload.count }.
        by(1)
    end

    context "branch containing a JIRA issue key" do

      let(:payload) do
        base = base_payload
        base["pull_request"]["head"]["ref"] = "jt-1234"
        base.to_json
      end

      let(:expected_body) do
        "{\"body\":\"Opened PR: https://github.com/jobteaser/job_tomate/pull/3\"}"
      end

      it "adds a comment on the JIRA with the PR link" do
        stub = stub_jira_request_as_job_tomate(
          :post,
          "http://job_tomate_username:job_tomate_pwd@/issue/jt-1234/comment",
          expected_body
        )
        request
        expect(stub).to have_been_requested
      end
    end

    context "branch not containing a JIRA issue key" do
      it "doesn't add a JIRA comment" do
        request
        # Fails if a request is done because we don't
        # stub the JIRA request.
      end
    end
  end
end
