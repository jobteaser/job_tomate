require "spec_helper"
require "data/user"
require "errors/jira"

describe "change assignee sets product_manager" do
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
      product_manager: product_manager
    )
  end
  let(:developer_backend) { false }
  let(:jira_reviewer) { false }
  let(:product_manager) { false }

  context "assignee is unknown" do
    let!(:assignee) { nil }

    it "fails with a JIRA::UnknownUser exception" do
      error = JobTomate::Errors::JIRA::UnknownUser
      message = "no user with jira_username == \"romain.champourlier\""
      expect { play_request }.to raise_error(error, message)
    end
  end

  context "assignee is a product manager" do
    let(:product_manager) { true }

    ["Open", "In Development", "In Review", "In Functional Review"].each do |status|
      context "status is \"#{status}\"" do
        let(:payload_override) { { issue_status: status } }
        let(:expected_body) do
          { fields: { customfield_11200: { name: "romain.champourlier" } } }.to_json
        end

        it "sets the feature owner with the assignee" do
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

    context "issue already has a product_manager" do
      let(:payload_override) { { issue_product_manager: "anyone" } }

      it "is successful and does nothing" do
        play_request
        expect(last_response).to be_ok
      end
    end
  end

  context "assignee is not a JIRA feature owner" do
    let(:product_manager) { false }

    it "is successful and does nothing" do
      play_request
      expect(last_response).to be_ok
    end
  end
end
