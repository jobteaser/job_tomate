# frozen_string_literal: true

require "spec_helper"
require "data/user"
require "errors/jira"

describe "Jira issue status changed notifies developer on Slack if missing pull request" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:payload_name) { :issue_updated_changed_field_status }
  let(:payload_override) { { issue_status: "Open" } }
  let(:jira_username) { "user.name" }
  let(:issue_key) { "JT-4467" }
  let(:issue_type_name) { "Task" }
  let(:slack_username) { "user.name" }

  let!(:user) do
    JobTomate::Data::User.create(
      jira_username: jira_username,
      developer_backend: false,
      jira_reviewer: false,
      product_manager: false,
      slack_username: slack_username
    )
  end

  let(:changelog_to_string) { "In Development" } # same value as in :jira_issue_update fixture
  let(:comment) do
    { "comments" => [
      { "body" => "Opened PR: some link", "author" => { name: "job_tomate" } }
    ] }
  end
  let(:issue_bug_cause) { "Some serious cause!" }

  let(:webhook) do
    wh = JobTomate::Data::StoredWebhook.load_from_fixture(:jira_issue_update)
    parsed_body = wh.value.parsed_body
    parsed_body["issue"]["fields"]["issuetype"]["name"] = issue_type_name
    parsed_body["issue"]["fields"]["customfield_11101"] = issue_bug_cause
    parsed_body["changelog"]["items"][0]["toString"] = changelog_to_string
    parsed_body["issue"]["fields"]["comment"] = comment
    wh.body = parsed_body.to_json
    wh
  end

  let(:link) { "<https://example.atlassian.net/browse/#{issue_key}|#{issue_key}>" }
  let(:expected_slack_message_body) do
    {
      text: "You have probably forgotten to create a pull request for this issue In Review => #{link}",
      channel: "@#{slack_username}",
      username: "JobTomate",
      icon_emoji: ":tomato:"
    }.to_json
  end

  context "pull request is missing from comments" do
    before do
      allow(JobTomate::Commands::JIRA::UpdateIssue).to receive(:run).and_return(WebmockHelpers::RETURN_VALUES)
    end

    context "status changed to \"In Development\"" do
      it "does nothing" do
        # there is no webmock stub so it fails if a request is done
        receive_stored_webhook(webhook)
      end
    end

    context "status changed to \"In Review\"" do
      let(:changelog_to_string) { "In Review" }
      let(:comment) { nil }

      it "notifies the updater of the issue" do
        stub = stub_slack_request(expected_slack_message_body, return_values: WebmockHelpers::RETURN_VALUES)
        receive_stored_webhook(webhook)
        expect(stub).to have_been_requested
      end
    end
  end

  context "pull request is present in comments" do

    before do
      # We stub this request because this use case will trigger an unrelated
      # action (update assignee on status change)
      stub_request(:put, "https://example.atlassian.net/rest/api/2/issue/JT-4467?startAt=0").
        with(
          body: "{\"fields\":{\"assignee\":null}}",
          headers: {
            "Authorization" => "Basic am9iX3RvbWF0ZV91c2VybmFtZTpqb2JfdG9tYXRlX3B3ZA==",
            "Content-Type" => "application/json"
          }
        ).to_return(status: 200, body: "", headers: {})
    end

    it "does nothing" do
      # there is no webmock stub so it fails if a request is done
      receive_stored_webhook(webhook)
    end
  end
end
