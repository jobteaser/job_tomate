require 'spec_helper'
require 'job_tomate/input/jira/comments_rules'
require 'job_tomate/output/slack_webhook'

describe JobTomate::Input::Jira::CommentsRules do
  let(:jira_issue_url_base) { ENV['JIRA_ISSUE_URL_BASE'] }
  let(:jira_issue_key) { 'key' }
  let(:user) do
    JobTomate::User.create(
      'jira_username' => 'jira_user',
      'slack_username' => 'slack_user'
    )
  end

  describe '.apply(webhook_data)' do
    subject { described_class.apply(webhook_data) }
    let(:webhook_data) do
      base = {
        'webhookEvent' => webhook_event,
        'issue' => { 'key' => jira_issue_key }
      }
      return base if webhook_data_comment.nil?
      base.merge('comment' => webhook_data_comment)
    end
    let(:webhook_data_comment) { nil }

    context 'created issue event' do
      let(:webhook_event) { 'jira:issue_created' }
      it 'does nothing' do
        expect(JobTomate::Output::SlackWebhook).not_to receive(:send)
        subject
      end
    end

    context 'updated issue event' do
      let(:webhook_event) { 'jira:issue_updated' }

      context 'added comment' do
        let(:webhook_data_comment) { { 'body' => comment_body } }
        let(:comment_body) { 'some text' }

        context 'with mentioned user in body' do
          let(:comment_body) { "[~#{comment_jira_username}] and some text" }

          context 'mentioned user exist in JobTomate\'s DB' do
            let(:comment_jira_username) { user.jira_username }

            context 'has Slack username' do
              it 'sends a notification to the mentioned user on Slack' do
                expect(JobTomate::Output::SlackWebhook).to receive(:send) do |message, options|
                  expected_message = "You were mentioned in a comment on " \
                    "<#{jira_issue_url_base}/#{jira_issue_key}|#{jira_issue_key}>: #{comment_body}"
                  expect(message).to eq(expected_message)
                  expect(options[:channel]).to eq("@#{user.slack_username}")
                end
                subject
              end
            end

            context 'hasn\'t Slack username' do
              before { user.slack_username = nil; user.save }

              it 'does nothing' do
                expect(JobTomate::Output::SlackWebhook).not_to receive(:send)
                subject
              end
            end
          end

          context 'mentioned user doesn\'t exist in JobTomate\'s DB' do
            let(:comment_jira_username) { 'unknown_jira_username' }
            it 'does nothing' do
            expect(JobTomate::Output::SlackWebhook).not_to receive(:send)
              subject
            end
          end

          context 'mentioned several users found in JobTomate\'s DB' do
            let(:other_user) do
              JobTomate::User.create(
                'jira_username' => 'jira_username_2',
                'slack_username' => 'slack_username_2'
              )
            end
            let(:comment_body) { "[~#{user.jira_username}] and [~#{other_user.jira_username}]" }

            it 'notifies all users' do
              expect(JobTomate::Output::SlackWebhook).to receive(:send).twice
              subject
            end
          end
        end

        context 'with no mentioned user in body' do
          let(:comment_body) { 'some random text' }
          it 'does nothing' do
            expect(JobTomate::Output::SlackWebhook).not_to receive(:send)
            subject
          end
        end
      end

      context 'did not add comment' do
        let(:comment_body) { nil }
        it 'does nothing' do
          expect(JobTomate::Output::SlackWebhook).not_to receive(:send)
          subject
        end
      end
    end
  end
end
