require "spec_helper"

describe "new JIRA maintenance blocker issue notifies #maintenance channel on Slack" do
  include WebhooksHelpers
  include WebmockHelpers

  def play_request
    post_webhook_jira(payload_name, payload_override)
  end

  let(:payload_name) { :issue_created }
  let(:payload_override) { { issue_category: category, issue_priority: priority } }

  context "not maintenance" do
    let(:category) { "Technical" }
    let(:priority) { "Major" }

    it "is successful and does nothing" do
      play_request
      expect(last_response).to be_ok
    end
  end

  context "maintenance" do
    let(:category) { "Maintenance" }

    context "not blocker" do
      let(:priority) { "Critical" }

      it "is successful and does nothing" do
        play_request
        expect(last_response).to be_ok
      end
    end

    context "blocker" do
      let(:priority) { "Blocker" }

      it "notifies the Slack #maintenance channel" do
        url_prefix = "https://example.atlassian.net/browse"
        expected_text = "New blocker issue has just been created! => <#{url_prefix}/JT-3838|JT-3838>"
        stub = stub_slack_send_message_as_job_tomate(expected_text, "#maintenance")
        play_request
        expect(stub).to have_been_requested
      end
    end
  end
end
