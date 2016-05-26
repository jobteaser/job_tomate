require "spec_helper"
require "job_tomate/commands/jira/support/client"

# The client records requests in `Data::StoredRequests`. You can use these
# stored requests to build test (see `StoredRequest#write_to_fixture`). You
# can then mock HTTP requests using Webmock thanks to the `webmock_with_stored_request`
# helper.
describe JobTomate::Commands::JIRA::Client do
  include WebmockHelpers

  # TODO: test using webmock instead of stubbing HTTParty
  describe "::exec_request(verb, url_suffix, username, password, body, params = {})" do

    context "unauthorized" do
      it "raises a `JIRA::Unauthorized` error" do
        webmock_with_stored_request(:jira_add_worklog_unauthorized)
        expect {
          described_class.exec_request(
            :post,
            "/issue/JT-1234/worklog",
            nil,
            nil,
            { "timeSpentSeconds" => 10_000, "started" => "2016-05-26T22:03:39.038+0000" },
            {}
          )
        }.to raise_error(JobTomate::Errors::JIRA::Unauthorized)
      end
    end

    context "not found" do
      it "raises a `JIRA::NotFound` error" do
        webmock_with_stored_request(:jira_get_issue_not_found)
        expect {
          described_class.exec_request(
            :get,
            "/issue/unknown",
            "username",
            "password",
            nil,
            {}
          )
        }.to raise_error(JobTomate::Errors::JIRA::NotFound)
      end
    end

    context "not paginated" do

      it "returns the response" do
        webmock_with_stored_request(:jira_get_issue_success)
        result = described_class.exec_request(:get, "/issue/23825", "username", "password", nil, {})
        expect(result["id"]).to eq("23825")
      end
    end

    context "paginated" do

      it "returns the merged responses" do
        webmock_with_stored_request(:jira_search_issues_page_1)
        webmock_with_stored_request(:jira_search_issues_page_2)
        result = described_class.exec_request(:get, "/search", "username", "password", nil, "jql" => 'PROJECT = "JT"')
        expect(result["issues"].count).to eq(3)
      end
    end
  end
end
