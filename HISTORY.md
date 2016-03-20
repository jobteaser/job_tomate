# HISTORY

## 2016-01-17

Tried to perform a full sync of Toggl reports to update all JIRA worklogs. Seems to complicated because of many issues:
- the team wasn't fully using Toggl before mid-2015,
- some worklogs have been created independently from Toggl (in particular by Benjamin's FTG tool),
- FTG is setting the start time of most worklogs it creates to 11:00, making it difficult to match worklogs with reports by looking at the start time...

Abandoning this quest.

After that, I started the implementation of the sync for new reports. Some things have been done, I must pursue on `workflows/toggl/process_pending_entries.rb`.

The last option to improve the data seems to be:
  - calculate the total timespent for Toggl and JIRA for each issue,
  - compare them and if the difference is significative (e.g > 1h),
    do something (hopefully, there should be not many issues to check)
    => see `syncing_old.rb` file.
