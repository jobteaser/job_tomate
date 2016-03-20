require "spec_helper"
require "data/user"
require "errors/jira"

describe "status change sets assignee" do
  include WebhooksHelpers
  include WebmockHelpers

  def play_request
    post_webhook_jira(payload_name, payload_override)
  end
  let(:payload_name) { :issue_updated_changed_field_status }
  let(:payload_override) { { issue_status: "Open" } }
  let(:jira_username) { "romain.champourlier" }

  let!(:assignee) do
    JobTomate::Data::User.create(
      jira_username: jira_username,
      jira_developer: false,
      jira_reviewer: false,
      jira_feature_owner: false
    )
  end

  context "status is \"Open\"" do
    let(:payload_override) { { issue_status: "Open" } }

    it "is successful and does nothing" do
      play_request
      expect(last_response).to be_ok
    end
  end

  {
    "In Development" => "developer",
    "In Review" => "reviewer",
    "In Functional Review" => "feature_owner",
    "Ready for Release" => "developer"
  }.each do |status, role|

    context "status is \"#{status}\"" do
      let(:payload_override) { { issue_status: status } }

      context "issue has no #{role}" do
        let(:payload_override) do
          {
            :issue_status => status,
            :"issue_#{role}" => nil
          }
        end

        it "is successful and does nothing" do
          play_request
          expect(last_response).to be_ok
        end
      end

      context "issue has a #{role}" do
        let(:payload_override) do
          {
            :issue_status => status,
            :"issue_#{role}" => jira_username
          }
        end

        context "which is unknown" do
          before { assignee.destroy }

          it "fails with a JIRA::UnknownUser exception" do
            error = JobTomate::Errors::JIRA::UnknownUser
            message = "no user with jira_username == \"#{jira_username}\""
            expect { play_request }.to raise_error(error, message)
          end
        end

        context "which is known" do
          before { expect(assignee).not_to be_nil }

          let(:expected_body) do
            { fields: { assignee: { name: jira_username } } }.to_json
          end

          it "sets her has assignee" do
            stub = stub_jira_request(
              :put,
              "/issue/JT-3838",
              expected_body
            )
            play_request
            expect(stub).to have_been_requested
          end
        end
      end
    end
  end
end
