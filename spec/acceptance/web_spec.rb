require "spec_helper"
require "rack/test"

require "job_tomate/web"

describe "JobTomate::Web" do
  include RackTestHelpers

  let(:data) { { test: "data" } }

  describe "GET /" do
    it 'says "ok"' do
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to eq({ status: "ok" }.to_json)
    end
  end

  describe "POST /webhooks/jira" do
    it 'responds with a 400 if called with an invalid webhook' do
      post "/webhooks/jira"
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq({status: "invalid webhook" }.to_json)
    end
  end

  describe "POST /webhooks/github" do
    it 'responds with a 400 if called with an invalid webhook' do
      post "/webhooks/github"
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq({status: "invalid webhook" }.to_json)
    end
  end
end
