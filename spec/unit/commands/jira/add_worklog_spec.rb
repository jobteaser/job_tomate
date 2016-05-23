require "spec_helper"
require "timecop"
require "commands/jira/add_worklog"

describe JobTomate::Commands::JIRA::AddWorklog do
  describe ".run(issue_key, username, password, time_spent, start)" do
    context "JIRA_DRY_RUN" do
      let(:time) { Timecop.freeze(Time.now); Time.now }
      before { ENV["JIRA_DRY_RUN"] = "true" }
      after  { ENV["JIRA_DRY_RUN"] = "false" }

      # No webmock ensures no HTTP call is done
      it "doesn't perform an HTTP call" do
        described_class.run("JT-1234", "jira_username", "jira_password", 100, Time.now)
      end

      it "logs the request details" do
        expected_log = "JobTomate::Commands::JIRA::AddWorklog.run [\"JT-1234\", \"jira_username\", \"jira_password\", 100, #{time}]"
        expect(JobTomate::LOGGER).to receive(:info).with(expected_log)
        described_class.run("JT-1234", "jira_username", "jira_password", 100, Time.now)
      end
    end
  end
end
