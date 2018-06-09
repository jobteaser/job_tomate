# frozen_string_literal: true

require "spec_helper"
require "data/user"
require "errors/jira"

describe "notifies on Slack if Jira \"Bug\" issue is updated without a bug cause" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:jira_username) { "user.name" }
  let(:issue_key) { "JT-4467" }
  let(:slack_username) { "user.name" }
  let(:changelog_to_string) { "In Development" } # same value as in :jira_issue_update fixture

  let!(:user) do
    JobTomate::Data::User.create(
      jira_username: jira_username,
      slack_username: slack_username
    )
  end

  let(:webhook) do
    wh = JobTomate::Data::StoredWebhook.load_from_fixture(:jira_issue_update)
    parsed_body = wh.value.parsed_body
    parsed_body["issue"]["fields"]["issuetype"]["name"] = issue_type_name
    parsed_body["issue"]["fields"]["customfield_11101"] = bug_cause
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

  before do
    # The stored webhook `jira_issue_update` simulates an update of the issue
    # to the "In Development" status and thus trigger other actions.
    # We are testing Slack-related commands so we can just ignore this
    # JIRA command.
    allow(JobTomate::Commands::JIRA::UpdateIssue).to receive(:run).and_return(WebmockHelpers::RETURN_VALUES)
  end

  context "updated issue is ef type 'Bug'" do
    let(:issue_type_name) { "Bug" }

    context "and 'Bug Cause' field is not set" do
      let(:bug_cause) { nil }

      it "sends a Slack message" do
        stub_slack = stub_slack_request(expected_slack_body)
        receive_stored_webhook(webhook)
        expect(stub_slack).to have_been_requested
      end
    end

    context "and 'Bug Cause' fields is set" do
      let(:bug_cause) { "Some serious cause!" }

      it "does not send a Slack message" do
        receive_stored_webhook(webhook)
        expect(last_response).to be_ok
      end
    end
  end

  context "updated issue is not of type 'Bug' and 'Bug Cause' field is not set" do
    let(:issue_type_name) { "Task" } # not bug
    let(:bug_cause) { nil }

    it "does not send a Slack message" do
      receive_stored_webhook(webhook)
      expect(last_response).to be_ok
    end
  end
end
