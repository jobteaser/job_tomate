# frozen_string_literal: true

require "spec_helper"
require "data/user"
require "errors/jira"

describe "JIRA issue status changed updates assignee and roles" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:payload_name) { :issue_updated_changed_field_status }
  let(:payload_override) { { issue_status: "Open" } }
  let(:jira_username) { "user.name" }
  let(:issue_key) { "JT-4467" }
  let(:issue_type_name) { "Task" }
  let(:slack_username) { "user.name" }

  let(:user_is_developer_backend) { false }
  let(:user_is_reviewer) { false }
  let(:user_is_product_manager) { false }

  let!(:user) do
    JobTomate::Data::User.create(
      jira_username: jira_username,
      developer_backend: user_is_developer_backend,
      jira_reviewer: user_is_reviewer,
      product_manager: user_is_product_manager,
      slack_username: slack_username
    )
  end

  let(:issue_developer_backend_name) { nil }
  let(:issue_reviewer_name) { nil }
  let(:issue_product_manager_name) { nil }
  let(:issue_developer_backend) { issue_developer_backend_name.nil? ? nil : { name: issue_developer_backend_name } }
  let(:issue_reviewer) { issue_reviewer_name.nil? ? nil : { name: issue_reviewer_name } }
  let(:issue_product_manager) { issue_product_manager_name.nil? ? nil : { name: issue_product_manager_name } }
  let(:changelog_to_string) { "In Development" } # same value as in :jira_issue_update fixture
  let(:comments) { [{ "body" => "Opened PR: some link" , "author" => { name: "job_tomate" } }] }

  let(:webhook) do
    wh = JobTomate::Data::StoredWebhook.load_from_fixture(:jira_issue_update)
    parsed_body = wh.value.parsed_body
    parsed_body["issue"]["fields"]["issuetype"]["name"] = issue_type_name
    parsed_body["issue"]["fields"]["customfield_10600"] = issue_developer_backend
    parsed_body["issue"]["fields"]["customfield_10601"] = issue_reviewer
    parsed_body["issue"]["fields"]["customfield_11200"] = issue_product_manager
    parsed_body["changelog"]["items"][0]["toString"] = changelog_to_string
    parsed_body["issue"]["fields"]["comment"]["comments"] = comments
    wh.body = parsed_body.to_json
    wh
  end

  context "when issue changed to \"Open\"" do
    let(:changelog_to_string) { "Open" }

    it "does nothing" do
      receive_stored_webhook(webhook)
      expect(last_response).to be_ok
    end
  end

  # Special case: the backend developer may move the issue to "In Review" and herself
  # be a potential reviewer. In the case the user is already the issue's
  # backend developer, we must not set her as the reviewer and instead unassign the
  # issue.
  context "when issue is changed to \"In Review\" with no reviewer set and user is reviewer and the issue's backend developer" do
    let(:changelog_to_string) { "In Review" }
    let(:issue_developer_backend_name) { jira_username }
    let(:user_is_reviewer) { true }

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

  # Special case: the issue is a Bug and its status is changed to "In Functional
  # Review". The issue is assigned to the issue's reporter, even if a product
  # manager is defined.
  context "when issue is changed to \"In Functional Review\" and is a bug" do
    let(:changelog_to_string) { "In Functional Review" }
    let(:issue_reporter_name) { jira_username }
    let(:issue_product_manager_name) { "product.manager" }
    let(:issue_type_name) { "Bug" }

    it "assigns the issue to its reporter" do
      expected_body = {
        fields: {
          assignee: { name: jira_username },
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

  context "to In Review status change checks if comments contain a PR link" do
    before do
      allow(JobTomate::Commands::JIRA::UpdateIssue).to receive(:run).and_return(WebmockHelpers::RETURN_VALUES)
    end

    let(:changelog_to_string) { "In Review" }
    let(:link) { "<https://example.atlassian.net/browse/#{issue_key}|#{issue_key}>" }
    let(:expected_body) do
      {
        text: "You have probably forgotten to create a pull request for this issue In Review => #{link}",
        channel: "@#{slack_username}",
        username: "Git Patrol",
        icon_emoji: ":rotating_light:"
      }.to_json
    end

    context "comments are absent" do
      let(:comments) { [] }

      it "notifies the updater of the issue" do
        stub = stub_slack_request(expected_body, return_values: WebmockHelpers::RETURN_VALUES)
        receive_stored_webhook(webhook)
        expect(stub).to have_been_requested
      end
    end

    it "doesn't notify the updater of the issue if a comment with a pull request link is present" do
      stub = stub_slack_request(expected_body, return_values: WebmockHelpers::RETURN_VALUES)
      receive_stored_webhook(webhook)
      expect(stub).to_not have_been_requested
    end
  end

  {
    "In Development" => "developer_backend",
    "In Review" => "reviewer",
    "In Functional Review" => "product_manager",
    "Ready for Release" => "developer_backend"
  }.each do |status, role|
    context "when issue is changed to \"#{status}\"" do
      let(:changelog_to_string) { status }

      context "given #{role} is not set" do
        let(:"issue_#{role}_name") { nil }

        context "and user is unknown" do
          before { user.destroy }

          it "fails with a JIRA::UnknownUser exception" do
            error = JobTomate::Errors::JIRA::UnknownUser
            message = "no user with jira_username == \"#{jira_username}\""
            expect { receive_stored_webhook(webhook) }.to raise_error(error, message)
          end
        end

        context "and user is a #{role}" do
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

        context "and user is not #{role}" do
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

      context "given #{role} is set" do
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
end
