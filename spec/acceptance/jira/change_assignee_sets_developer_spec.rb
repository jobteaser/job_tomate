require "spec_helper"
require "data/user"
require "errors/jira"

describe "change assignee sets backend developer" do
  include WebhooksHelpers
  include WebmockHelpers

  def play_request
    post_webhook_jira(payload_name, payload_override)
  end
  let(:payload_name) { :issue_updated_changed_field_assignee }
  let(:payload_override) { {} }

  let!(:assignee) do
    JobTomate::Data::User.create(
      jira_username: "romain.champourlier",
      developer_backend: developer_backend,
      jira_reviewer: jira_reviewer,
      jira_feature_owner: jira_feature_owner
    )
  end
  let(:developer_backend) { false }
  let(:jira_reviewer) { false }
  let(:jira_feature_owner) { false }
  after { assignee.destroy if assignee }

  context "assignee is unknown" do
    let!(:assignee) { nil }

    it "fails with a JIRA::UnknownUser exception" do
      error = JobTomate::Errors::JIRA::UnknownUser
      message = "no user with jira_username == \"romain.champourlier\""
      expect { play_request }.to raise_error(error, message)
    end
  end

  context "assignee is a backend developer" do
    let(:developer_backend) { true }

    ["Open", "In Development"].each do |status|
      context "status is \"#{status}\"" do
        let(:payload_override) { { issue_status: status } }
        let(:expected_body) do
          { fields: { customfield_10600: { name: "romain.champourlier" } } }.to_json
        end

        it "sets the backend developer with the assignee" do
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

    ["In Review", "In Functional Review"].each do |status|
      context "status is \"#{status}\"" do
        let(:payload_override) { { issue_status: status } }

        it "is successful and does nothing" do
          play_request
          expect(last_response).to be_ok
        end
      end
    end

    context "issue already has a backend developer" do
      let(:payload_override) { { issue_developer_backend: "anyone" } }

      it "is successful and does nothing" do
        play_request
        expect(last_response).to be_ok
      end
    end
  end

  context "assignee is not a backend developer" do
    let(:developer_backend) { false }

    it "is successful and does nothing" do
      play_request
      expect(last_response).to be_ok
    end
  end
end
