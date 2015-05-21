module JobTomate
  class TogglProcessor

    # Perform a run where:
    #   - it fetches Toggl entries for today,
    #   - create the new TogglEntry documents for entries that
    #     have not been created yet,
    #   - update the entries that have already been created
    #     (update their `toggl_update` field and `status`).
    def self.run
      reports = TogglClient.fetch_reports(Time.now)
      reports.each do |report|
        toggl_id = report['id']
        toggl_updated = Time.parse(report['updated'])

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
      end
    end
  end
end
