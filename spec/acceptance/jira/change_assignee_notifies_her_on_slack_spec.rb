require "spec_helper"
require "data/user"
require "errors/jira"

describe "change assignee notifies her on Slack" do
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
      slack_username: "rchampourlier"
    )
  end

  context "assignee is changed to none" do
    let(:payload_override) { { issue_assignee: nil } }

    it "is successful and does nothing" do
      play_request
      expect(last_response).to be_ok
    end
  end

  context "assignee is unknown" do
    let!(:assignee) { nil }

    it "fails with a JIRA::UnknownUser exception" do
      error = JobTomate::Errors::JIRA::UnknownUser
      message = "no user with jira_username == \"romain.champourlier\""
      expect { play_request }.to raise_error(error, message)
    end
  end

  context "assignee is known" do

    context "assignee has a Slack username" do
      it "notifies her" do
        expected_text = "You've been assigned to <https://jobteaser.atlassian.net/rest/api/2/issue/21816|JT-3839> (Open)"
        stub = stub_slack_send_message_as_job_tomate(expected_text, "@rchampourlier")
        play_request
        expect(stub).to have_been_requested
      end
    end

    context "assignee has no Slack username" do
      let!(:assignee) { JobTomate::Data::User.create(jira_username: "romain.champourlier") }

      it "logs a warning message" do
        expect(JobTomate::LOGGER).to receive(:warn).with("unknown Slack username for user ##{assignee.id}")
        play_request
      end
    end
  end
end
