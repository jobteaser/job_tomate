require 'active_support/all'

module JobTomate
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
        if jira_report?(toggl_report)
          entry = create_or_update_entry(toggl_report)
          if add_to_jira?(entry)
            if add_worklog_to_jira(toggl_report)
              mark_entry_added_to_jira(entry)
              :sent_to_jira
            else
              :failed_to_send_to_jira
            end
          else
            :already_sent_to_jira
          end
        else
          :ignored
        end
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
        entry.status = 'new'
      end

      entry.toggl_updated = toggl_updated
      entry.save
      entry
    end

    def self.jira_report?(toggl_report)
      !!(jira_issue_key(toggl_report))
    end

    def self.jira_issue_key(toggl_report)
      toggl_report['description'][/jt-[\d]+/i]
    end

    def self.time_spent_seconds(toggl_report)
      toggl_report['dur'] / 1000
    end

    # @param entry [TogglEntry]
    def self.add_to_jira?(entry)
      !!(entry.status =~ /new/) # accepts "new" and "new_updated"
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
        puts "User for toggl_user #{toggl_user} not found"
        false
      end
      time_spent = time_spent_seconds(toggl_report)
      JiraClient.add_worklog(
        issue_key,
        username,
        password,
        time_spent
      )
    end

    def self.mark_entry_added_to_jira(entry)
      entry.status = 'sent_to_jira'
      entry.save
    end
  end
end
