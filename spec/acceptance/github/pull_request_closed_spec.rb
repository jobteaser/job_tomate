require "spec_helper"
require "job_tomate/web"
require "job_tomate/data/stored_webhook"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:payload_override) { {} }
  def play_request
    post_webhook_github_super(:pull_request, payload_name, payload_override)
  end

  context "closed pull request" do
    context "branch containing a JIRA issue key" do
      let(:payload_override) { { pull_request_head_ref: "jt-1234" } }

      let!(:stub) do
        stub_jira_request(
          :post,
          "/issue/jt-1234/comment",
          expected_body
        )
      end

      context "merged" do
        let(:payload_name) { :pull_request_closed_merged }
        let(:expected_body) do
          "{\"body\":\"Merged PR in wip: https://github.com/jobteaser/job_tomate/pull/4\"}"
        end

        it "is successful" do
          play_request
          expect(last_response).to be_ok
        end

        it "stores the payload" do
          expect { play_request }.
            to change { JobTomate::Data::StoredWebhook.count }.
            by(1)
        end

        it "adds a comment on the JIRA with the PR link" do
          stub = stub_jira_request(
            :post,
            "/issue/jt-1234/comment",
            expected_body
          )
          play_request
          expect(stub).to have_been_requested
        end
      end

      context "not merged" do
        let(:payload_name) { :pull_request_closed_not_merged }
        let(:expected_body) do
          "{\"body\":\"Closed PR without merging: https://github.com/jobteaser/job_tomate/pull/5\"}"
        end

        it "is successful" do
          play_request
          expect(last_response).to be_ok
        end

        it "adds a comment on the JIRA with the PR link" do
          play_request
          expect(stub).to have_been_requested
        end
      end
    end

    context "branch not containing a JIRA issue key" do
      let(:payload_name) { :pull_request_closed_not_merged }

      it "doesn't add a JIRA comment" do
        play_request
        # Fails if a request is done because we don't
        # stub the JIRA request.
      end
    end
  end
end
