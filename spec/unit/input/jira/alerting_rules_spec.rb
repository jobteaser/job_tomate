require 'spec_helper'
require 'job_tomate/input/jira/alerting_rules'
require 'job_tomate/output/slack_webhook'

describe JobTomate::Input::Jira::AlertingRules do

  describe '.apply(webhook_data)' do
    let(:count_todo) { 0 }
    let(:count_wip) { 0 }
    let(:issue_priority) { 'Major' }
    let(:status_to_string) { 'Open' }
    let(:webhook_data) do
      {
        'webhookEvent' => "jira:issue_#{webhook_event}",
        'changelog' => {
          'items' => [
            {
              'field' => 'status',
              'toString' => status_to_string
            }
          ]
        },
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

    context 'created maintenance issue' do
      let(:webhook_event) { 'created' }

      context 'blocker' do
        let(:issue_priority) { 'Blocker' }
        it 'sends a notification for the creation of a blocker issue' do
          expect(JobTomate::Output::SlackWebhook).to receive(:send) do |msg, options|
            expect(msg).to match(/New blocker issue has just been created!/)
          end
          described_class.apply(webhook_data)
        end
      end

      context 'count of todo and wip issues not at a level value' do

        context 'count is 9' do
          let(:count_todo) { 5 }
          let(:count_wip) { 4 }

          it 'does not send a Slack notification' do
            expect(JobTomate::Output::SlackWebhook).not_to receive(:send)
            described_class.apply(webhook_data)
          end
        end

        context 'count is 11' do
          let(:count_todo) { 5 }
          let(:count_wip) { 6 }

          it 'does not send a Slack notification' do
            expect(JobTomate::Output::SlackWebhook).not_to receive(:send)
            described_class.apply(webhook_data)
          end
        end
      end

      context '10 todo and wip issues' do
        let(:count_todo) { 5 }
        let(:count_wip) { 5 }

        it 'sends a Slack notification to #maintenance channel for level 1 maintenance' do
          expect(JobTomate::Output::SlackWebhook).to receive(:send) do |msg, options|
            expect(msg).to match(/Maintenance reached level 1/)
          end
          described_class.apply(webhook_data)
        end
      end

      context '15 todo and wip issues' do
        let(:count_todo) { 10 }
        let(:count_wip) { 5 }

        it 'sends a Slack notification to #maintenance channel for level 2 maintenance' do
          expect(JobTomate::Output::SlackWebhook).to receive(:send) do |msg, options|
            expect(msg).to match(/Maintenance reached level 2/)
          end
          described_class.apply(webhook_data)
        end
      end

      context '20 todo and wip issues' do
        let(:count_todo) { 10 }
        let(:count_wip) { 10 }

        it 'sends a Slack notification to #maintenance channel for level 3 maintenance' do
          expect(JobTomate::Output::SlackWebhook).to receive(:send) do |msg, options|
            expect(msg).to match(/Maintenance reached level 3/)
          end
          described_class.apply(webhook_data)
        end
      end
    end

    context 'updated maintenance issue' do
      let(:webhook_event) { 'updated' }

      context 'blocker' do
        let(:issue_priority) { 'Blocker' }
        let(:status_to_string) { 'Open' }
        it 'does not send a notification' do
          expect(JobTomate::Output::SlackWebhook).not_to receive(:send)
          described_class.apply(webhook_data)
        end
      end

      context 'changed status to "In Development"' do
        let(:status_to_string) { 'In Development' }

        context 'exactly 9 WIP maintenance issues' do
          let(:count_todo) { 5 }
          let(:count_wip) { 4 }

          it 'does not send a Slack notification' do
            expect(JobTomate::Output::SlackWebhook).not_to receive(:send)
            described_class.apply(webhook_data)
          end
        end
      end

      context 'changed status to "In Functional Review"' do
        let(:status_to_string) { 'In Functional Review' }

        context 'exactly 9 WIP maintenance issues' do
          let(:count_todo) { 5 }
          let(:count_wip) { 4 }

          it 'sends a notification maintenance out of level 1' do
            expect(JobTomate::Output::SlackWebhook).to receive(:send) do |msg, options|
              expect(msg).to match(/Maintenance back to normal/)
            end
            described_class.apply(webhook_data)
          end
        end
      end
    end
  end
end
