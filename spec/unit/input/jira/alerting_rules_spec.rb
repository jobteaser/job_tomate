require 'spec_helper'
require 'job_tomate/input/jira/alerting_rules'
require 'job_tomate/output/slack_webhook'

describe JobTomate::Input::Jira::AlertingRules do

  describe '.apply(webhook_data)' do

    context 'created issue' do
      context 'more than 5 maintenance issues in TODO and WIP statuses' do

        let(:webhook_data) do
          {
            'webhookEvent' => 'jira:issue_created',
            'issue' => {
              'fields' => { 'customfield_10400' => 'Maintenance'}
            }
          }
        end

        before do
          expect(JobTomate::Interface::JiraClient).to receive(:exec_request) do |action, path, usr, pwd, body, params|
            expect(action).to eq(:get)
            expect(path).to eq('/search')
            expect(body).to eq({})
            expect(params[:jql]).to match(/status IN/i)
            expect(params[:jql]).to match(/(Open|In Development|In Review)/i)
          end.twice.and_return({ 'total' => 3 })
        end

        it 'send a Slack notification to #maintenance channel' do
          expect(JobTomate::Output::SlackWebhook).to receive(:send) do |msg, options|
            expect(msg).to match(/too much maintenance/i)
          end
          described_class.apply(webhook_data)
        end
      end
    end
  end
end
