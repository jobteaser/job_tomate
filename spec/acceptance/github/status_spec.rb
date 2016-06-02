require "spec_helper"
require "data/stored_webhook"
require "errors/github"
require "errors/slack"
require "web"

describe "/webhooks/github" do
  include WebhooksHelpers
  include WebmockHelpers

  context "status change received" do
    let!(:stub) do
      expected_text = "[jira-issue] ci/circleci - Your tests passed on CircleCI!"
      expected_channel = "slack_user"
      stub_slack_send_message_as_job_tomate(expected_text, expected_channel)
    end

    context "pull request sender is known" do
      before do
        JobTomate::Data::User.create(
          github_user: "developer",
          slack_username: "slack_user"
        )
      end

      it "is successful" do
        receive_stored_webhook(:github_status_update)
        expect(last_response).to be_ok
      end

      it "notifies the pull request submitter of the status update" do
        receive_stored_webhook(:github_status_update)
        expect(stub).to have_been_requested
      end
    end

    context "pull request sender is unkown" do
      it "fails with a Errors::Github::UnknownUser error" do
        expect {
          receive_stored_webhook(:github_status_update)
        }.to raise_error(JobTomate::Errors::Github::UnknownUser)
      end
    end

    context "pull request sender has no Slack username" do
      before do
        JobTomate::Data::User.create(
          github_user: "developer",
          slack_username: ""
        )
      end

      it "fails with a Errors::Slack::MissingUsername error" do
        expect {
          receive_stored_webhook(:github_status_update)
        }.to raise_error(JobTomate::Errors::Slack::MissingUsername)
      end
    end
  end
end
