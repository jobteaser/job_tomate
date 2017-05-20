require "spec_helper"
require "timecop"
require "commands/jira/update_worklog"

describe JobTomate::Commands::JIRA::UpdateWorklog do
  describe ".run(issue_key, worklog_id, username, password, time_spent, start)" do
    context "JIRA_DRY_RUN" do
      let(:time) { Timecop.freeze(Time.now); Time.now }

      before { ENV["JIRA_DRY_RUN"] = "true" }
      after { ENV["JIRA_DRY_RUN"] = "false" }

      # No webmock ensures no HTTP call is done
      it "doesn't perform an HTTP call" do
        described_class.run("JT-1234", "worklog_id", "jira_username", "jira_password", 100, Time.now)
      end

      it "logs the request details" do
        expected_log_start = "JobTomate::Commands::JIRA::UpdateWorklog.run transaction='tuuid' - START"
        expected_log_end = "JobTomate::Commands::JIRA::UpdateWorklog.run transaction='tuuid' - END"
        expect(JobTomate::LOGGER).to receive(:info).with(expected_log_start)
        expect(JobTomate::LOGGER).to receive(:info) do |args|
          args =~ %r{#{expected_log_end}.*}
        end
        described_class.run("JT-1234", "worklog_id", "jira_username", "jira_password", 100, Time.now)
      end
    end
  end
end
