require 'spec_helper'
require 'job_tomate/github_processor'

describe JobTomate::GithubProcessor do

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

    it 'works' do
      described_class.run(webhook_data)
    end
  end
end
