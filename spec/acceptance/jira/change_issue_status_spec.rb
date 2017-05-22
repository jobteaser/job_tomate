require "spec_helper"
require "data/user"
require "errors/jira"

describe "change issue status" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:payload_name) { :issue_updated_changed_field_status }
  let(:payload_override) { { issue_status: "Open" } }
  let(:jira_username) { "user.name" }
  let(:issue_key) { "JT-4467" }

  let(:user_is_developer) { false }
  let(:user_is_reviewer) { false }
  let(:user_is_feature_owner) { false }
  let(:slack_username) { 'user.name' }

  let!(:user) do
    JobTomate::Data::User.create(
      jira_username: jira_username,
      jira_developer: user_is_developer,
      jira_reviewer: user_is_reviewer,
      jira_feature_owner: user_is_feature_owner,
      slack_username: slack_username
    )
  end

  let(:issue_developer_name) { nil }
  let(:issue_reviewer_name) { nil }
  let(:issue_feature_owner_name) { nil }
  let(:issue_developer) { issue_developer_name.nil? ? nil : { name: issue_developer_name } }
  let(:issue_reviewer) { issue_reviewer_name.nil? ? nil : { name: issue_reviewer_name } }
  let(:issue_feature_owner) { issue_feature_owner_name.nil? ? nil : { name: issue_feature_owner_name } }
  let(:changelog_to_string) { "In Development" } # same value as in :jira_issue_update fixture

  let(:webhook) do
    wh = JobTomate::Data::StoredWebhook.load_from_fixture(:jira_issue_update)
    parsed_body = wh.value.parsed_body
    parsed_body["issue"]["fields"]["customfield_10600"] = issue_developer
    parsed_body["issue"]["fields"]["customfield_10601"] = issue_reviewer
    parsed_body["issue"]["fields"]["customfield_11200"] = issue_feature_owner
    parsed_body["changelog"]["items"][0]["toString"] = changelog_to_string
    wh.body = parsed_body.to_json
    wh
  end

  context "to \"Open\"" do
    let(:changelog_to_string) { "Open" }

    it "is successful and does nothing" do
      receive_stored_webhook(webhook)
      expect(last_response).to be_ok
    end
  end

  # Special case: the developer may move the issue to "In Review" and herself
  # be a potential reviewer. In the case the user is already the issue's
  # developer, we must not set her as the reviewer and instead unassign the
  # issue.
  context "to \"In Review\" with no reviewer set and user is reviewer and the issue's developer" do
    let(:changelog_to_string) { "In Review" }
    let(:issue_developer_name) { jira_username }
    let(:user_is_reviewer) { true }

    it "is unassigns the issue" do
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

  {
    "In Development" => "developer",
    "In Review" => "reviewer",
    "In Functional Review" => "feature_owner",
    "Ready for Release" => "developer"
  }.each do |status, role|
    context "to \"#{status}\"" do
      let(:changelog_to_string) { status }

      context "issue's #{role} is not set" do
        let(:"issue_#{role}_name") { nil }

        context "user is unknown" do
          before { user.destroy }

          it "fails with a JIRA::UnknownUser exception" do
            error = JobTomate::Errors::JIRA::UnknownUser
            message = "no user with jira_username == \"#{jira_username}\""
            expect { receive_stored_webhook(webhook) }.to raise_error(error, message)
          end
        end

        context "user is a #{role}" do
          let(:"user_is_#{role}") { true }

          it "sets the #{role} and assigns the issue to the user" do
            expected_body = {
              fields: {
                assignee: { name: jira_username },
                JobTomate::Values::JIRA::Issue.jira_field(role).to_sym => { name: jira_username }
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

        context "user is not #{role}" do
          let(:"user_is_#{role}") { false }

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

      context "issue's #{role} is set" do
        let(:"issue_#{role}_name") { jira_username }

        it "assigns the issue to the set #{role}" do
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
  end

  context "for a bug issue and" do
    before do 
      allow(JobTomate::Commands::JIRA::UpdateIssue).to receive(:run).and_return(WebmockHelpers::RETURN_VALUES)
    end
    let(:issue_developer_name) { jira_username }
    
    context "get a slack notification because" do
      let(:webhook_for_slack_notification) do
        wh = JobTomate::Data::StoredWebhook.load_from_fixture(:jira_issue_update)
        parsed_body = wh.value.parsed_body
        parsed_body["issue"]["fields"]["customfield_10600"] = issue_developer
        parsed_body["issue"]["fields"]["issuetype"]["name"] = "Bug"
        parsed_body["issue"]["fields"]["customfield_11101"] = nil
        parsed_body["issue"]["fields"]["assignee"] = issue_developer
        wh.body = parsed_body.to_json
        wh
      end

      let(:expected_slack_body) do
        issue_link = "<https://example.atlassian.net/browse/JT-4467|JT-4467>"
        {
          text: "The bug issue you're working on doesn't have a cause specified.
Please do something about it! #{issue_link} (#{changelog_to_string})",
          channel: "@#{slack_username}",
          username: "Bug Monster",
          icon_emoji: ":smiling_imp:"
        }.to_json
      end

      it "the bug cause field is empty" do
        stub_slack = stub_slack_request(expected_slack_body)
        receive_stored_webhook(webhook_for_slack_notification)
        expect(stub_slack).to have_been_requested
      end
    end

    context "have no slack notifications because" do
      let(:webhook_for_no_slack_notification) do 
        wh = JobTomate::Data::StoredWebhook.load_from_fixture(:jira_issue_update)
        parsed_body = wh.value.parsed_body
        parsed_body["issue"]["fields"]["issuetype"]["name"] = "Bug"
        parsed_body["issue"]["fields"]["customfield_11101"] = "It just happened"
        wh.body = parsed_body.to_json
        wh
      end

      it "the bug cause is filled in" do
        expect(JobTomate::Actions::SlackNotifyJIRABugIssueUpdatedWithoutCause).not_to receive(:run)
        receive_stored_webhook(webhook_for_no_slack_notification)
      end

      it "the bug has no assignee" do
        body = webhook_for_no_slack_notification.value.parsed_body
        body["issue"]["fields"]["customfield_11101"] = nil
        webhook_for_no_slack_notification.body = body.to_json

        expect(JobTomate::Actions::SlackNotifyJIRABugIssueUpdatedWithoutCause).not_to receive(:send_message)
        receive_stored_webhook(webhook_for_no_slack_notification)
      end
    end
  end
end
