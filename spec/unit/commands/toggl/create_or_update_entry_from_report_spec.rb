require 'spec_helper'
require 'timecop'
require 'job_tomate/commands/toggl/create_or_update_entry_from_report'

describe JobTomate::Commands::Toggl::CreateOrUpdateEntryFromReport do
  include Fixtures
  include Helpers

  describe '#run(report)' do
    context 'new entry' do
      it 'creates a new entry record' do
        expect {
          described_class.run(toggl_report)
        }.to change { JobTomate::Data::TogglEntry.count }.by(1)
        entry = JobTomate::Data::TogglEntry.first
        expect(entry.jira_issue_key).to eq('jt-1234')
      end
    end

    context 'existing entry' do
      context 'with unchanged "updated"' do
        let!(:entry) { described_class.run(toggl_report) }
        let(:updated_report) do
          toggl_report.merge(
            'dur' => 2_442_100,
            'description' => 'jt-2345 updated description',
            'start' => '2015-07-31T11:10:10+02:00',
            'user' => 'Me'
          )
        end

        it 'doesn\'t change the entry' do
          expect {
            Timecop.travel(1.minute.from_now) do
              described_class.run(updated_report)
            end
          }.not_to change { entry.reload.updated_at }
        end
      end

      context 'with changed "updated"' do
        before { described_class.run(toggl_report) }
        let(:updated_report) do
          toggl_report.merge(
            'dur' => 2_442_100,
            'description' => 'jt-2345 updated description',
            'start' => '2015-07-31T11:10:10+02:00',
            'updated' => '2015-07-31T11:11:10+02:00',
            'user' => 'Me'
          )
        end

        # We expect to reset the JIRA worklog id because
        # it must be set when processing the entry. We
        # check the previous sync (if any, values are saved
        # in history) is valid by checking the previously
        # synced worklog.
        #
        # NB: using `expect_hash_match` because an equality
        #     match on these hashes whould not work because of
        #     the time values changing timezone.
        it 'updates the existing entry with new values' do
          entry = described_class.run(updated_report)
          expect_hash_match(entry.attributes, {
            status: 'pending',
            toggl_description: updated_report['description'],
            toggl_duration: updated_report['dur'] / 1000,
            toggl_started: Time.parse(updated_report['start']),
            toggl_updated: Time.parse(updated_report['updated']),
            toggl_user: updated_report['user'],
            jira_issue_key: 'jt-2345',
            jira_worklog_id: nil
          }.stringify_keys)
        end

        # NB: using `expect_hash_match` because an equality
        #     match on these hashes whould not work because of
        #     the time values changing timezone.
        it 'stores old values in a new history entry' do
          Timecop.freeze do
            entry = described_class.run(updated_report)
            expect(entry.history.count).to eq(1)
            expect_hash_match(entry.history.first, {
              status: 'pending',
              toggl_description: toggl_report['description'],
              toggl_duration: toggl_report['dur'] / 1000,
              toggl_started: Time.parse(toggl_report['start']),
              toggl_updated: Time.parse(toggl_report['updated']),
              toggl_user: toggl_report['user'],
              jira_issue_key: 'jt-1234',
              time: Time.now
            }.stringify_keys)
          end
        end
      end
    end
  end
end
