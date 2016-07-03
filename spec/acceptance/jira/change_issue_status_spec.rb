require "spec_helper"
require "data/user"
require "errors/jira"

# This specs currently uses 2 ways of generating webhooks:
#   - `receive_stored_webhook` which is the more recent one and
#     bases the simulated requests on real webhook data. This method
#     is now the preferred one, as it may be used for any webhook
#     provider.
#   - `post_webhook_jira` which builds a webhook request from partial
#     real data.
describe "change issue status" do
  include WebhooksHelpers
  include WebmockHelpers

  def play_request
    post_webhook_jira(payload_name, payload_override)
  end
  let(:payload_name) { :issue_updated_changed_field_status }
  let(:payload_override) { { issue_status: "Open" } }
  let(:jira_username) { "user.name" }
  let(:issue_key) { "JT-4467" }

  let(:is_developer) { false }
  let(:is_reviewer) { false }
  let(:is_feature_owner) { false }

  let!(:assignee) { user } # retrocompatibility for older specs
  let!(:user) do
    JobTomate::Data::User.create(
      jira_username: jira_username,
      jira_developer: is_developer,
      jira_reviewer: is_reviewer,
      jira_feature_owner: is_feature_owner
    )
  end

  context "to \"In Development\"" do

    let(:issue_developer_name) { nil }
    let(:issue_reviewer_name) { nil }
    let(:issue_feature_owner_name) { nil }
    let(:issue_developer) { issue_developer_name.nil? ? nil : { name: issue_developer_name } }
    let(:issue_reviewer) { issue_reviewer_name.nil? ? nil : { name: issue_reviewer_name } }
    let(:issue_feature_owner) { issue_feature_owner_name.nil? ? nil : { name: issue_feature_owner_name } }

    let(:webhook) do
      wh = JobTomate::Data::StoredWebhook.load_from_fixture(:jira_issue_update)
      parsed_body = wh.value.parsed_body
      parsed_body["issue"]["fields"]["customfield_10600"] = issue_developer
      parsed_body["issue"]["fields"]["customfield_10601"] = issue_reviewer
      parsed_body["issue"]["fields"]["customfield_11200"] = issue_feature_owner
      wh.body = parsed_body.to_json
      wh
    end

    context "issue's developer is not set" do
      let(:issue_developer_name) { nil }

      context "user is unknown" do
        before { user.destroy }

        it "fails with a JIRA::UnknownUser exception" do
          error = JobTomate::Errors::JIRA::UnknownUser
          message = "no user with jira_username == \"#{jira_username}\""
          expect { receive_stored_webhook(webhook) }.to raise_error(error, message)
        end
      end

      context "user is a developer" do
        let(:is_developer) { true }

        it "sets the developer and assigns the issue to the user" do
          expected_body = {
            fields: {
              assignee: { name: jira_username },
              customfield_10600: { name: jira_username }
            }
          }.to_json
          stub = stub_jira_request(
            :put,
            "/issue/#{issue_key}",
            expected_body
          )
          receive_stored_webhook(webhook)
          expect(stub).to have_been_requested
        end
      end

      context "user is not developer" do
        let(:is_developer) { false }

        it "unassigns the issue" do
          expected_body = {
            fields: {
              assignee: nil
            }
          }.to_json
          stub = stub_jira_request(
            :put,
            "/issue/#{issue_key}",
            expected_body
          )
          receive_stored_webhook(webhook)
          expect(stub).to have_been_requested
        end
      end
    end

    context "issue's developer is set" do
      let(:issue_developer_name) { jira_username }

      it "assigns the issue to the set developer" do
        expected_body = {
          fields: {
            assignee: { name: jira_username }
          }
        }.to_json
        stub = stub_jira_request(
          :put,
          "/issue/#{issue_key}",
          expected_body
        )
        receive_stored_webhook(webhook)
        expect(stub).to have_been_requested
      end
    end
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

        it "unassigns the issue" do
          expected_body = { fields: { assignee: nil } }.to_json
          stub = stub_jira_request(
            :put,
            "/issue/JT-3838",
            expected_body
          )
          play_request
          expect(stub).to have_been_requested
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
