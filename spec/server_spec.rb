require 'spec_helper'

describe JobTomate::JiraClient do
  context "A worklog is added." do
    let!(:attributes) do
      {
        issue_key: 'jt-2253',
        username: 'thomas.barroqueiro',
        password: 'tbjobteaser135',
        time_spent: ''
      }
    end
    it 'Sets developer variable' do
      post '/webhooks/status', attributes
      JiraProcessor.last.developer.should eq 'david.ruyer'
    end
  end
  context "A comment is added after a PR relative action." do
    let!(:attributes) do
      {
        issue_key: 'jt-2253',
        username: 'thomas.barroqueiro',
        password: 'tbjobteaser135',
        comment: 'blabla'
      }
    end
    it 'Sets developer variable' do
      post '/webhooks/status', attributes
      JiraProcessor.last.developer.should eq 'david.ruyer'
    end
  end
  context "A user as to be assigned to the ticket." do
    let!(:attributes) do
      {
        issue_key: 'jt-2253',
        username: 'thomas.barroqueiro',
        password: 'tbjobteaser135',
        assignee: 'david.ruyer'
      }
    end
    it 'Sets developer variable' do
      post '/webhooks/status', attributes
      JiraProcessor.last.developer.should eq 'david.ruyer'
    end
  end
end