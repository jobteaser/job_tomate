require "spec_helper"

require "rack/test"

require "job_tomate/web"
require "job_tomate/data/webhook_payload"
require "job_tomate/workflows/github/process_pull_request_webhook"
require "job_tomate/workflows/jira/process_webhook"

describe "JobTomate::Web" do
  include Rack::Test::Methods

  def app
    JobTomate::Web
  end

  let(:data) { { test: "data" } }

  describe "GET /" do
    it 'says "ok"' do
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to eq({ status: "ok" }.to_json)
    end
  end

  describe "POST /webhooks/github/pull_request" do
    before { allow(JobTomate::Workflows::Github::ProcessPullRequestWebhook).to receive(:run) }

    it "writes the payload to a WebhookPayload record" do
      expect { post "/webhooks/github/pull_request", data.to_json }.
        to change { JobTomate::Data::WebhookPayload.count }.by(1)
      expect(last_response).to be_ok
      expect(last_response.body).to eq({ status: "ok" }.to_json)

      payload = JobTomate::Data::WebhookPayload.last
      expect(payload.source).to eq("github/pull_request")
      expect(payload.data).to eq(data.stringify_keys)
    end
  end

  describe "POST /webhooks/jira" do
    before { allow(JobTomate::Workflows::Jira::ProcessWebhook).to receive(:run) }

    it "writes the payload to a WebhookPayload record" do
      expect { post "/webhooks/jira", data.to_json }.to change { JobTomate::Data::WebhookPayload.count }.by(1)
      expect(last_response).to be_ok
      expect(last_response.body).to eq({ status: "ok" }.to_json)

      payload = JobTomate::Data::WebhookPayload.last
      expect(payload.source).to eq("jira")
      expect(payload.data).to eq(data.stringify_keys)
    end
  end
end
