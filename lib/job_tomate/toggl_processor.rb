require 'active_support/all'
require 'job_tomate/toggl_entry'
require 'job_tomate/toggl_client'
require 'job_tomate/user'
require 'job_tomate/interface/jira_client'

module JobTomate

  # API request:
  # `https://toggl.com/reports/api/v2/details?user_agent=JobTomate (<dev@jobteaser.com>)&workspace_id=939576&page=5`
  #
  # - Paginated: use `page` parameter
  #
  # Processing rules:
  # - Identify new entries, if not updated for 2 hours,
  #   adds the corresponding worklog to JIRA. (This
  #   allows an entry to be modified during 2 hours
  #   after its creation.)
  class TogglProcessor

    # Perform a run where:
    #   - it fetches Toggl entries for today,
    #   - create the new TogglEntry documents for entries that
    #     have not been created yet,
    #   - update the entries that have already been created
    #     (update their `toggl_update` field and `status`).
    def self.run
      reports = TogglClient.fetch_reports(Date.yesterday, Date.today)
      reports.map do |toggl_report|
        process_toggl_report(toggl_report)
      end
    end

    def self.process_toggl_report(toggl_report)
      return :not_linked_to_jira unless linkable_to_jira?(toggl_report)
      return :not_old_enough unless old_enough?(toggl_report)

      entry = create_or_update_entry(toggl_report)
      return :already_sent_to_jira if sent_to_jira?(entry)

      if add_worklog_to_jira(toggl_report)
        mark_entry_added_to_jira(entry)
        :successfully_sent_to_jira
      else
        :failed_to_send_to_jira
      end
    end

    def self.create_or_update_entry(toggl_report)
      toggl_id = toggl_report['id']
      toggl_updated = Time.parse(toggl_report['updated'])

      if (entry = TogglEntry.where(toggl_id: toggl_id).first)
        if entry.toggl_updated != toggl_updated
          entry.status += '_modified'
        end
      else
        entry = TogglEntry.new
        entry.toggl_id = toggl_id
        entry.status = 'pending'
      end

      entry.toggl_updated = toggl_updated
      entry.save
      entry
    end

    # Returns `true` if the Toggl report can be linked to a JIRA issue.
    def self.linkable_to_jira?(toggl_report)
      !!(jira_issue_key(toggl_report))
    end

    def self.old_enough?(toggl_report)
      updated_at = Time.parse(toggl_report['updated'])
      updated_at < 2.hours.ago
    end

    def self.jira_issue_key(toggl_report)
      toggl_report['description'][/jt-[\d]+/i]
    end

    def self.time_spent_seconds(toggl_report)
      toggl_report['dur'] / 1000
    end

    def self.jira_format_date(toggl_report)
      original_date = DateTime.parse(toggl_report['start'])
      original_date.strftime('%Y-%m-%dT%H:%M:%S.%3N%z')
    end

    # Returns `true` if the Toggl entry has been sent to JIRA,
    # i.e. the status contains `sent_to_jira`.
    # @param entry [TogglEntry]
    def self.sent_to_jira?(entry)
      !!(entry.status =~ /sent_to_jira/)
    end

    def self.credentials_for_toggl_report(toggl_report)
      toggl_user = toggl_report['user']
      user = User.where(toggl_user: toggl_user).first
      user ? [user.jira_username, user.jira_password] : nil
    end

    def self.add_worklog_to_jira(toggl_report)
      issue_key = jira_issue_key(toggl_report)
      username, password = credentials_for_toggl_report(toggl_report)
      toggl_user = toggl_report['user']

      if username.nil?
        LOGGER.warn "User for toggl_user \"#{toggl_user}\" not found"
        return false
      end

      time_spent = time_spent_seconds(toggl_report)
      start = jira_format_date(toggl_report)
      JobTomate::Interface::JiraClient.add_worklog(
        issue_key,
        username,
        password,
        time_spent,
        start
      )
    end

    def self.mark_entry_added_to_jira(entry)
      entry.status = 'sent_to_jira'
      entry.save
    end
  end
end
