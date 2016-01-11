require 'spec_helper'
require 'job_tomate/workflows/jira/rules/people'
require 'job_tomate/commands/slack/send_message'

describe JobTomate::Workflows::Jira::Rules::People do

  describe '.apply(webhook_data)' do
    let(:count_todo) { 0 }
    let(:count_wip) { 0 }
    let(:issue_priority) { 'Major' }
    let(:issue_type_name) { 'Bug' }
    let(:webhook_event) { 'jira:issue_created' }
    let(:webhook_data_base) do
      {
        'webhookEvent' => "jira:issue_#{webhook_event}",
        'issue' => {
          'fields' => {
            'issuetype' => {
              'name' => issue_type_name
            },
            'customfield_10400' => {
              'value' => 'Maintenance'
            },
            'priority' => { 'name' => issue_priority }
          }
        }
      }
    end
    let(:webhook_data) { webhook_data_base }

    describe 'notify new assignee' do
    end

    describe 'update people' do

      context 'issue type = "Spec"' do
        let(:issue_type_name) { 'Spec' }

        it 'does nothing' do
          expect(described_class).not_to receive(:perform_update_people)
          described_class.apply(webhook_data)
        end
      end

      context 'other issue type' do

        context 'no status change' do
          it 'does nothing' do
            expect(described_class).not_to receive(:perform_update_people)
            described_class.apply(webhook_data)
          end
        end

        context 'with status change(s)' do

          let(:webhook_data) do
            webhook_data_base.merge(
              'changelog' => {
                'items' => [
                  'field' => 'status'
                ]
              }
            )
          end

          it 'performs the people update' do
            expect(described_class).to receive(:perform_update_people).with(webhook_data)
            described_class.apply(webhook_data)
          end
        end
      end
    end
  end
end
