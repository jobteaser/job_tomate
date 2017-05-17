require "spec_helper"
require "data/user"

describe "Slack notify on JIRA issue comment" do
  include WebhooksHelpers
  include WebmockHelpers

  let(:request) do
    post_webhook_jira(payload_name, payload_override)
  end
  let(:payload_name) { :issue_updated_with_comment }
  let(:payload_override) { {} }

  context "no mentioned user" do
    let(:payload_override) { { comment_body: "no one mentioned" } }

    it "is successful and does nothing" do
      request
      expect(last_response).to be_ok
    end
  end

  context "mentioned user is unknown" do
    before do
      JobTomate::Data::User.create(jira_username: "unknown")
    end

    it "is successful and does nothing" do
      request
      expect(last_response).to be_ok
    end
  end

  context "mentioned user's Slack username is unknown" do
    before do
      JobTomate::Data::User.create(jira_username: "romain.champourlier")
    end

    it "is successful and does nothing" do
      request
      expect(last_response).to be_ok
    end
  end

  context "mentioned user's Slack username is known" do
    before do
      JobTomate::Data::User.create(
        jira_username: "romain.champourlier",
        slack_username: "rchampourlier"
      )
    end

    let(:issue_link) { "https://example.atlassian.net/browse/JT-3839" }

    let(:expected_body) do
      prefix = "You have been mentioned in a comment on <#{issue_link}|JT-3839>:"
      {
        text: "#{prefix} *Trying a comment with some people mentioned: @rchampourlier*",
        channel: "@rchampourlier",
        username: "JobTomate",
        icon_emoji: ":japanese_ogre:"
      }.to_json
    end

    it "sends a message to the corresponding user on Slack" do
      stub = stub_slack_request(expected_body)
      request
      expect(stub).to have_been_requested
    end
  end

  context "several mentioned users" do
    let(:payload_override) do
      {
        comment_body: "mentioned [~romain.champourlier] and [~some.known], [~some.no_slack], [~some.unknown]"
      }
    end

    let(:issue_link) { "https://example.atlassian.net/browse/JT-3839" }

    def build_expected_body(channel)
      prefix = "You have been mentioned in a comment on <#{issue_link}|JT-3839>:"
      {
        text: "#{prefix} *mentioned @rchampourlier and @knownslack, [~some.no_slack], [~some.unknown]*",
        channel: channel,
        username: "JobTomate",
        icon_emoji: ":japanese_ogre:"
      }.to_json
    end

    before do
      [
        %w(romain.champourlier rchampourlier),
        %w(some.known knownslack),
        ["some.no_slack", nil]
      ].each do |jira_username, slack_username|
        JobTomate::Data::User.create(
          jira_username: jira_username,
          slack_username: slack_username
        )
      end
    end

    it "notifies the known ones and ignores the others" do
      stubs = %w(rchampourlier knownslack).map do |slack_username|
        stub_slack_request(build_expected_body("@#{slack_username}"))
      end
      request
      stubs.each { |stub| expect(stub).to have_been_requested }
    end
  end
end
