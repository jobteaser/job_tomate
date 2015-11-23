require 'spec_helper'
require 'job_tomate/input/jira/alerting_rules'
require 'job_tomate/output/slack_webhook'

describe JobTomate::Input::Jira::AlertingRules do

  describe '.apply(webhook_data)' do

    context 'created maintenance issue' do
      let(:webhook_data) do
        {
          'webhookEvent' => 'jira:issue_created',
          'issue' => {
            'fields' => {
              'customfield_10400' => {
                'value' => 'Maintenance'
              }
            }
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
        end.twice.and_return({ 'total' => half_count })
      end

      context 'less than 10 todo and wip issues' do
        let(:half_count) { 4 }

        it 'does not send a Slack notification' do
          expect(JobTomate::Output::SlackWebhook).not_to receive(:send)
          described_class.apply(webhook_data)
        end
      end

      context '10 todo and wip issues' do
        let(:half_count) { 5 }

        it 'sends a Slack notification to #maintenance channel for level 1 maintenance' do
          expect(JobTomate::Output::SlackWebhook).to receive(:send) do |msg, options|
            expect(msg).to match(/Maintenance reached level 1/)
          end
          described_class.apply(webhook_data)
        end
      end

      context '14 todo and wip issues' do
        let(:half_count) { 7 }

        it 'sends a Slack notification to #maintenance channel for level 2 maintenance' do
          expect(JobTomate::Output::SlackWebhook).to receive(:send) do |msg, options|
            expect(msg).to match(/Maintenance reached level 2/)
          end
          described_class.apply(webhook_data)
        end
      end

      context '18 todo and wip issues' do
        let(:half_count) { 9 }

        it 'sends a Slack notification to #maintenance channel for level 3 maintenance' do
          expect(JobTomate::Output::SlackWebhook).to receive(:send) do |msg, options|
            expect(msg).to match(/Maintenance reached level 3/)
          end
          described_class.apply(webhook_data)
        end
      end
    end
  end
end
