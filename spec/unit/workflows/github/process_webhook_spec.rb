require 'spec_helper'
require 'job_tomate/workflows/github/process_webhook'

describe JobTomate::Workflows::Github::ProcessWebhook do

  describe '.run(webhook_data)' do

    let(:webhook_data) do
      {
        'action' => 'opened',
        'pull_request' => {
          'head' => { 'ref' => 'test' },
          'html_url' => 'test'
        }
      }
    end

    before do
      response = double(code: 200)
      allow(JobTomate::Commands::Jira::Client).to receive(:exec_request).and_return(response)
    end

    it 'works' do
      described_class.run(webhook_data)
    end
  end
end
