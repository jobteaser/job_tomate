require "spec_helper"
require "triggers/tasks/fetch_toggl_reports"
require "timecop"
require "data/toggl_entry"
require "data/user"

describe "fetch_toggl_reports" do
  include WebmockHelpers

  before do
    Timecop.freeze(1.minute.ago)

    # Necessary to ensure the JIRA API calls are performed using the
    # correct user (the one associated to the worklog).
    JobTomate::Data::User.create(toggl_user: "Some User", jira_username: jira_username, jira_password: jira_password)
  end

  let(:since_date) { 1.day.ago.to_date }
  let(:until_date) { Date.today }
  let(:jira_username) { "jira-user" }
  let(:jira_password) { "jira-pwd" }
  let(:worklog_id) { rand(36**8).to_s(36) }

  # Returns the corresponding Toggl report fixture
  def mock_toggl(name, page: 1)
    response_body = Fixtures.toggl_report(name)
    stub_toggl_api(page, since_date.to_s, until_date.to_s, response_body)
  end

  # @param timespent [Numeric] seconds
  def mock_jira_post_worklog(issue_key, timespent)
    stub_jira_request(
      :post,
      "/issue/#{issue_key}/worklog",
      "{\"timeSpentSeconds\":#{timespent},\"started\":\"2016-05-06T17:22:09.000+0200\"}",
      response_body: { id: worklog_id }.to_json,
      username: jira_username,
      password: jira_password
    )
  end

  def mock_jira_put_worklog(issue_key, worklog_id, timespent)
    stub_jira_request(
      :put,
      "/issue/#{issue_key}/worklog/#{worklog_id}",
      "{\"timeSpentSeconds\":#{timespent},\"started\":\"2016-05-06T17:22:09.000+0200\"}",
      response_body: { id: worklog_id }.to_json,
      username: jira_username,
      password: jira_password
    )
  end

  def mock_jira_delete_worklog(issue_key, worklog_id)
    stub_jira_request(
      :delete,
      "/issue/#{issue_key}/worklog/#{worklog_id}",
      nil,
      response_body: "",
      username: jira_username,
      password: jira_password
    )
  end

  describe "new report not associated to JIRA" do
    before { mock_toggl(:report_1_base_not_related_to_jira) }

    # We ensure nothing else is done through Webmock which would raise an
    # error if any HTTP call was attempted.
    it "records a Toggl entry and does nothing" do
      expect {
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      }.to change { JobTomate::Data::TogglEntry.count }.by(1)
      entry = JobTomate::Data::TogglEntry.last
      expect(entry.status).to eq("not_related_to_jira")
    end
  end

  describe "new report associated to JIRA shorter than 1 minute" do
    before do
      mock_toggl(:report_3_base_shorter_than_1_minute)
    end

    it "records a Toggl entry and does nothing else" do
      expect {
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      }.to change { JobTomate::Data::TogglEntry.count }.by(1)
      entry = JobTomate::Data::TogglEntry.last
      expect(entry.status).to eq("too_short")
    end
  end

  describe "new report associated to JIRA longer than 1 minute" do
    before do
      mock_toggl(:report_2_base_syncable_to_jira)
      mock_jira_post_worklog("jt-1234", 580)
    end

    it "records a Toggl entry" do
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      expect(JobTomate::Data::TogglEntry.count).to eq(1)
      entry = JobTomate::Data::TogglEntry.last
      expect(entry.status).to eq("synced")
      expect(entry.jira_worklog_id).to eq(worklog_id)
    end

    it "adds a worklog on the associated JIRA" do
      stub = mock_jira_post_worklog("jt-1234", 580)
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      expect(stub).to have_been_requested
    end
  end

  describe "existing report unchanged" do

    before do
      mock_toggl(:report_1_base_not_related_to_jira)
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      Timecop.return
    end

    it "does not create a new entry" do
      expect {
        mock_toggl(:report_1_base_not_related_to_jira)
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      }.not_to change { JobTomate::Data::TogglEntry.count }
    end

    it "does not update the existing entry" do
      entry = JobTomate::Data::TogglEntry.last
      expect {
        mock_toggl(:report_1_base_not_related_to_jira)
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      }.not_to change { entry.reload.updated_at }
    end

    # This one would only fail if some HTTP request was done.
    it "does nothing else" do
      mock_toggl(:report_1_base_not_related_to_jira)
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
    end
  end

  describe "existing report not associated to JIRA with changed worklog" do

    before do
      mock_toggl(:report_1_base_not_related_to_jira)
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      Timecop.return
    end

    # We ensure nothing else is done through Webmock which would raise an
    # error if any HTTP call was attempted.
    it "updates the Toggl entry and does nothing" do
      entry = JobTomate::Data::TogglEntry.last
      expect {
        mock_toggl(:report_1_changed_duration)
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      }.to change { entry.reload.updated_at }
      expect(JobTomate::Data::TogglEntry.count).to eq(1)
    end
  end

  describe "existing report too short changed description" do

    before do
      mock_toggl(:report_3_base_shorter_than_1_minute)
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      Timecop.return
    end

    # No webmock except for Toggl requests to ensure nothing else is done.
    it "updates the Toggl entry and does nothing else" do
      entry = JobTomate::Data::TogglEntry.last
      expect {
        mock_toggl(:report_3_changed_duration_less_than_1_minute)
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      }.to change { entry.reload.updated_at }
      expect(entry.jira_worklog_id).to be_nil
    end
  end

  describe "existing report synced to JIRA changed to too short worklog" do

    before do
      mock_toggl(:report_2_base_syncable_to_jira)
      mock_jira_post_worklog("jt-1234", 580)
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      Timecop.return
    end

    it "updates the Toggl entry" do
      entry = JobTomate::Data::TogglEntry.last
      mock_jira_delete_worklog("jt-1234", worklog_id)
      expect {
        mock_toggl(:report_2_changed_duration_less_than_1_minute)
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      }.to change { entry.reload.updated_at }
      expect(entry.jira_worklog_id).to eq(nil)
      expect(entry.status).to eq("too_short")
    end

    it "deletes the previous worklog" do
      expected_request = mock_jira_delete_worklog("jt-1234", worklog_id)
      mock_toggl(:report_2_changed_duration_less_than_1_minute)
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      expect(expected_request).to have_been_requested
    end
  end

  describe "existing report too short changed to long enough" do

    before do
      mock_toggl(:report_3_base_shorter_than_1_minute)
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      Timecop.return
    end

    it "updates the Toggl entry" do
      entry = JobTomate::Data::TogglEntry.last
      mock_jira_post_worklog("jt-1234", 600)
      expect {
        mock_toggl(:report_3_changed_duration_more_than_1_minute)
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      }.to change { entry.reload.updated_at }
      expect(entry.jira_worklog_id).to eq(worklog_id)
    end

    it "adds a worklog to the associated JIRA" do
      expected_request = mock_jira_post_worklog("jt-1234", 600)
      mock_toggl(:report_3_changed_duration_more_than_1_minute)
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      expect(expected_request).to have_been_requested
    end
  end

  describe "existing report associated to JIRA with changed worklog" do

    before do
      mock_toggl(:report_2_base_syncable_to_jira)
      mock_jira_post_worklog("jt-1234", 580)
      JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      Timecop.return
    end

    it "updates the Toggl entry" do
      mock_jira_put_worklog("jt-1234", worklog_id, 1580)
      entry = JobTomate::Data::TogglEntry.last
      expect {
        mock_toggl(:report_2_changed_duration_more_than_1_minute)
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
      }.to change { entry.reload.updated_at }
    end

    context "previously associated to another JIRA" do
      before { mock_toggl(:report_2_changed_jira) }

      it "deletes the previous JIRA worklog" do
        mock_jira_post_worklog("jt-2345", 580)
        expected_stub = mock_jira_delete_worklog("jt-1234", worklog_id)
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
        expect(expected_stub).to have_been_requested
      end

      it "adds a worklog to the new associated JIRA" do
        expected_stub = mock_jira_post_worklog("jt-2345", 580)
        mock_jira_delete_worklog("jt-1234", worklog_id)
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
        expect(expected_stub).to have_been_requested
      end
    end

    context "previously associated to the same JIRA" do

      it "updates the JIRA worklog" do
        stub = mock_jira_put_worklog("jt-1234", worklog_id, 1580)
        mock_toggl(:report_2_changed_duration_more_than_1_minute)
        JobTomate::Triggers::Tasks::FetchTogglReports.run(since_date, until_date)
        expect(stub).to have_been_requested
      end
    end
  end
end
