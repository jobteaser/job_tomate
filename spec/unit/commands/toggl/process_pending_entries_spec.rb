require "spec_helper"
require "job_tomate/commands/jira/add_worklog"
require "job_tomate/commands/jira/delete_worklog"
require "job_tomate/commands/jira/update_worklog"
require "job_tomate/commands/toggl/create_or_update_entry_from_report"
require "job_tomate/commands/toggl/process_pending_entries"

describe JobTomate::Commands::Toggl::ProcessPendingEntries do
  include Fixtures

  def build_entry(overriden_attributes = {})
    JobTomate::Commands::Toggl::CreateOrUpdateEntryFromReport.run(
      toggl_report.merge(overriden_attributes)
    )
  end

  def build_user
    JobTomate::Data::User.create(
      toggl_user: toggl_report["user"],
      jira_username: jira_username,
      jira_password: jira_password
    )
  end

  before { build_user }
  let!(:entry) { build_entry }
  let(:jira_username) { "jira_username" }
  let(:jira_password) { "jira_password" }
  let(:worklog_id) { rand(36**8).to_s(36) }

  describe "::run()" do

    context "entry already synced" do
      before { described_class.run }

      it "not processed again" do
        expect { described_class.run }.not_to change { entry.reload.updated_at }
      end
    end

    context "entry not associated to a JIRA issue" do
      let!(:entry) { build_entry("description" => "not related to JIRA") }

      it "set its status to :not_related_to_jira" do
        expect { described_class.run }.
          to change { entry.reload.status }.
          from("pending").
          to("not_related_to_jira")
      end
    end

    context "entry associated to a JIRA issue" do

      context "without history" do

        describe "creates a new worklog" do

          specify "with the right JIRA username and password" do
            expect(JobTomate::Commands::Jira::AddWorklog).
              to receive(:run) do |*args|
                expect(args[1]).to eq(jira_username)
                expect(args[2]).to eq(jira_password)
              end.
              and_return([:ok, worklog_id])
            described_class.run
          end

          specify "with the right JIRA issue key, duration and time" do
            expect(JobTomate::Commands::Jira::AddWorklog).
              to receive(:run) do |*args|
                expect(args[0]).to eq("jt-1234")
                expect(args[3]).to eq(toggl_report["dur"] / 1000)
                expect(args[4] - Time.parse(toggl_report["start"])).to be < 1
              end.
              and_return([:ok, worklog_id])
            described_class.run
          end
        end

        it "sets the status to :synced_with_jira" do
          described_class.run
          expect(entry.reload.status).to eq("synced_with_jira")
        end
      end

      context "with history" do

        context "JIRA issue associated to the report did not change" do
          let(:report_attributes) { toggl_report_duration_changed }

          before do
            described_class.run
            JobTomate::Commands::Toggl::CreateOrUpdateEntryFromReport.run(
              report_attributes
            )
            expect(entry.reload.status).to eq("pending")
          end

          it "updates the worklogs" do
            expect(JobTomate::Commands::Jira::UpdateWorklog).
              to receive(:run).
              with(
                "jt-1234",
                entry.reload.history.last["jira_worklog_id"],
                jira_username,
                jira_password,
                report_attributes["dur"] / 1000,
                Time.parse(report_attributes["start"])
              )
            described_class.run
            entry.reload
          end

          it "sets the status to \"synced_with_jira\"" do
            described_class.run
            entry.reload
            expect(entry.status).to eq("synced_with_jira")
          end
        end

        context "JIRA issue associated to the report did change" do
          let(:report_attributes) { toggl_report_issue_changed }

          before do
            described_class.run
            JobTomate::Commands::Toggl::CreateOrUpdateEntryFromReport.run(
              report_attributes
            )
            expect(entry.reload.status).to eq("pending")
          end

          it "deletes the previous worklog" do
            expect(JobTomate::Commands::Jira::DeleteWorklog).
              to receive(:run).
              with(
                "jt-1234",
                entry.reload.history.last["jira_worklog_id"],
                jira_username,
                jira_password
              )
            described_class.run
            entry.reload
          end

          it "creates a new worklog" do
            expect(JobTomate::Commands::Jira::AddWorklog).
              to receive(:run) do |*args|
                expect(args[0]).to eq("jt-2345")
                expect(args[1]).to eq(jira_username)
                expect(args[2]).to eq(jira_password)
                expect(args[3]).to eq(toggl_report["dur"] / 1000)
                expect(args[4] - Time.parse(toggl_report["start"])).to be < 1
              end.
              and_return([:ok, worklog_id])
            described_class.run
          end

          it "sets the status to \"synced_with_jira\"" do
            described_class.run
            entry.reload
            expect(entry.status).to eq("synced_with_jira")
          end
        end
      end
    end
  end
end
