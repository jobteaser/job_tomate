# frozen_string_literal: true

require "spec_helper"
require "timecop"
require "commands/jira/add_comment"

describe JobTomate::Commands::JIRA::UpdateIssue do
  describe ".run(issue_key, body, username, password)" do
    context "JIRA_DRY_RUN" do

      before { ENV["JIRA_DRY_RUN"] = "true" }
      after  { ENV["JIRA_DRY_RUN"] = "false" }

      # No webmock ensures no HTTP call is done
      it "doesn't perform an HTTP call" do
        described_class.run("JT-1234", "", "jira_username", "jira_password")
      end

      it "logs the request details" do
        expected_log = "JobTomate::Commands::JIRA::UpdateIssue.run transaction='tuuid' - "
        expect(JobTomate::LOGGER).to receive(:info).twice do |string|
          string =~ Regexp.new(expected_log)
        end
        described_class.run("JT-1234", "", "jira_username", "jira_password")
      end
    end
  end
end
