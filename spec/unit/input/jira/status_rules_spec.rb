require 'spec_helper'
require 'job_tomate/input/jira/status_rules'
require 'job_tomate/output/slack_webhook'

describe JobTomate::Input::Jira::StatusRules do

  describe '.apply(webhook_data)' do
    let(:count_todo) { 0 }
    let(:count_wip) { 0 }
    let(:issue_priority) { 'Major' }
    let(:webhook_data_base) do
      {
        'webhookEvent' => "jira:issue_#{webhook_event}",
        'issue' => {
          'fields' => {
            'customfield_10400' => {
              'value' => 'Maintenance'
            },
            'priority' => { 'name' => issue_priority }
          }
        }
      }
    end

    before do
      expect(JobTomate::Interface::JiraClient).to receive(:exec_request) do |action, path, usr, pwd, body, params|
        expect(action).to eq(:get)
        expect(path).to eq('/search')
        expect(body).to eq({})
        expect(params[:jql]).to match(/status IN \('Open'\)/i)
      end.ordered.and_return({ 'total' => count_todo })
      expect(JobTomate::Interface::JiraClient).to receive(:exec_request) do |action, path, usr, pwd, body, params|
        expect(params[:jql]).to match(/status IN \('In Development', 'In Review'\)/i)
      end.ordered.and_return({ 'total' => count_wip })
    end

    describe 'notify new assignee' do

    end

    describe 'update people' do
    end
  end
end
