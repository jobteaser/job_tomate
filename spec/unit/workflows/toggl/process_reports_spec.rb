require 'spec_helper'
require 'job_tomate/workflows/toggl/process_reports'

describe JobTomate::Workflows::Toggl::ProcessReports do

  let(:report) do
    {
      'id' => 256_671_430,
      'pid' => 9_800_223,
      'tid' => nil,
      'uid' => 1_634_403,
      'description' => description,
      'start' => start,
      'end' => '2015-07-29T10:15:26+02:00',
      'updated' => updated_at.to_s,
      'dur' => time_spent,
      'user' => 'Romain',
      'use_stop' => true,
      'client' => nil,
      'project' => 'Maintenance',
      'project_color' => '0',
      'project_hex_color' => '#4dc3ff',
      'task' => nil,
      'billable' => 0.0,
      'is_billable' => false,
      'cur' => 'USD',
      'tags' => []
    }
  end

  let(:entry) do
    double('Data::TogglEntry', status: 'sent_to_jira')
  end

  let(:issue_key) { 'jt-2423' }
  let(:description) { issue_key }
  let(:updated_at) { 1.day.ago }
  let(:time_spent) { 3_251_000 }
  let(:start) { '2015-07-29T09:21:15+02:00' }

  describe '::process_toggl_report' do

    context 'the issue is not linkable to JIRA' do
      let(:description) { 'kzoajzal' }
      it 'does not create any entry' do
        expect(described_class).not_to receive(:create_or_update_entry)
        described_class.process_toggl_report(report)
      end
    end

    context 'the issue is linkable to JIRA' do
      context 'the issue is old enough' do

        it 'creates or updates an entry' do
          expect(described_class).to receive(:create_or_update_entry).with(report).and_return(entry)
          described_class.process_toggl_report(report)
        end

        context 'has already been sent to jira' do

          before do
            allow(described_class).to receive(:create_or_update_entry).and_return(entry)
          end

          it 'does not send the issue to jira' do
            expect(described_class).not_to receive(:add_worklog_to_jira)
            described_class.process_toggl_report(report)
          end
        end

        context 'has not been sent to jira' do

          it 'sends and add the entry to JIRA' do
            allow(described_class).to receive(:create_or_update_entry).and_return(entry)
            allow(described_class).to receive(:sent_to_jira?).and_return(false)
            expect(described_class).to receive(:add_worklog_to_jira).with(report).and_return(true)
            expect(described_class).to receive(:mark_entry_added_to_jira).with(entry)
            described_class.process_toggl_report(report)
          end
        end
      end

      context 'the issue is not old enough' do
        let(:updated_at) { Time.now }

        it 'does not create any entry' do
          expect(described_class).not_to receive(:create_or_update_entry)
          described_class.process_toggl_report(report)
        end
      end
    end
  end

  describe '::create_or_update_entry' do

    context 'the entry for the report exists' do
      before do
        described_class.create_or_update_entry(report)
      end

      it 'does not create a new entry' do
        expect {
          described_class.create_or_update_entry(report)
        }.not_to change {
          JobTomate::Data::TogglEntry.count
        }
      end
    end

    context 'the entry for the report does not exists' do
      it 'creates a new entry' do
        expect {
          described_class.create_or_update_entry(report)
        }.to change {
          JobTomate::Data::TogglEntry.count
        }.by(1)
      end
    end
  end

  describe '::add_worklog_to_jira(toggl_report)' do
    let(:jira_username) { 'jira_username' }
    let(:jira_password) { 'jira_password' }

    context 'matching user found' do

      before do
        JobTomate::Data::User.create(
          toggl_user: 'Romain',
          jira_username: jira_username,
          jira_password: jira_password
        )
      end

      it 'adds the worklog on JIRA' do
        expect(JobTomate::Commands::Jira::AddWorklog).to receive(:run).with(
          issue_key,
          jira_username,
          jira_password,
          time_spent / 1000,
          Time.parse(start)
        )
        described_class.add_worklog_to_jira(report)
      end
    end
  end
end
