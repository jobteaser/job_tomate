require "spec_helper"
require "job_tomate/commands/jira/support/client"

describe JobTomate::Commands::JIRA::Client do

  # TODO: test using webmock instead of stubbing HTTParty
  describe "::exec_request(verb, url_suffix, username, password, body, params = {})" do

    context "not paginated" do
      let(:response) do
        {
          "results" => %w(some results)
        }
      end

      it "returns the response" do
        expect(HTTParty).to receive(:send).with(
          :get,
          "#{ENV['JIRA_API_URL_PREFIX']}/url_suffix",
          headers: { "Content-Type" => "application/json" },
          query: { "startAt" => 0 },
          basic_auth: {
            username: "username",
            password: "password"
          },
          body: nil
        ).and_return(response)
        result = described_class.exec_request(:get, "/url_suffix", "username", "password", nil, {})
        expect(result).to eq(response)
      end
    end

    context "paginated" do
      let(:response_1) do
        {
          "results" => %w(some results),
          "startAt" => 0,
          "total" => 11,
          "maxResults" => 10
        }
      end
      let(:response_2) do
        {
          "results" => %w(and other results),
          "startAt" => 10,
          "total" => 11,
          "maxResults" => 10
        }
      end

      before do
        expect(HTTParty).
          to receive(:send).
          twice.
          and_return(response_1, response_2)
      end

      it "returns the merged responses" do
        result = described_class.exec_request(:get, "/url_suffix", "username", "password", nil, {})
        expect(result["results"]).to eq(response_1["results"] + response_2["results"])
      end
    end
  end
end
