require "spec_helper"
require "data/user"
require "errors/jira"

describe "change assignee sets reviewer" do
  include WebhooksHelpers
  include WebmockHelpers

  def play_request
    post_webhook_jira(payload_name, payload_override)
  end
  let(:payload_name) { :issue_updated_changed_field_assignee }
  let(:payload_override) { { issue_status: "In Review" } }

  let!(:assignee) do
    JobTomate::Data::User.create(
      jira_username: "romain.champourlier",
      jira_developer: jira_developer,
      jira_reviewer: jira_reviewer,
      jira_feature_owner: jira_feature_owner
    )
  end
  let(:jira_developer) { false }
  let(:jira_reviewer) { false }
  let(:jira_feature_owner) { false }

  context "assignee is unknown" do
    let!(:assignee) { nil }

    it "fails with a JIRA::UnknownUser exception" do
      error = JobTomate::Errors::JIRA::UnknownUser
      message = "no user with jira_username == \"romain.champourlier\""
      expect { play_request }.to raise_error(error, message)
    end
  end

  context "assignee is a JIRA reviewer" do
    let(:jira_reviewer) { true }

    ["In Review"].each do |status|
      context "status is \"#{status}\"" do
        let(:payload_override) { { issue_status: status } }
        let(:expected_body) do
          { fields: { customfield_10601: { name: "romain.champourlier" } } }.to_json
        end

        it "sets the reviewer with the assignee" do
          stub = stub_jira_request(
            :put,
            "/issue/JT-3839",
            expected_body
          )
          play_request
          expect(stub).to have_been_requested
        end
      end
    end

    ["Open", "In Development", "In Functional Review"].each do |status|
      context "status is \"#{status}\"" do
        let(:payload_override) { { issue_status: status } }

        it "is successful and does nothing" do
          play_request
          expect(last_response).to be_ok
        end
      end
    end

    context "issue already has a reviewer" do
      let(:payload_override) do
        {
          issue_reviewer: "anyone",
          issue_status: "In Review"
        }
      end

      it "is successful and does nothing" do
        play_request
        expect(last_response).to be_ok
      end
    end
  end

  context "assignee is not a JIRA reviewer" do
    let(:jira_reviewer) { false }

    it "is successful and does nothing" do
      play_request
      expect(last_response).to be_ok
    end
  end
end
