# JobTomate

## Purpose

Automate as many things as possible in our development workflow.

## What to automate?

- JIRA
- Github
- Toggl

## Possible workflows?

- [Automate|Toggl+JIRA] New time entry in Toggl => add workflow in JIRA => DONE
- [Automate|Github+JIRA] Merge a PR in develop, add the "Merged in develop" comment in JIRA. => DONE
Creating a PR add a comment in the jira issue with the PR url. => DONE
- [Automate|JIRA] Automatically assign the appropriate person when changing the issue status. => DONE
In "maintenance", when the reviewer or developer field is empty, assigns the user. => DONE
If there is a subtask, change its status to the same status than the task.
- [Alert|JIRA] send an email to the developer if the JIRA is changed to status "In Review" without a PR in the comments.
- [Automate|JIRA] PR validated in review (`:+1:` in the comments), add a comment in JIRA and change the issue's status to "Functional Review".
- [Automate|JIRA] PR validated in review (`:-1:` in the comments), add a comment in JIRA (including the comment on the PR) and change the issue's status to "In Dev".
- [Automate|Git+Github+JIRA] on a deploy, update the JIRA issue status and fix version for deployed issues (based on PRs merged in the deployed commit)
- [Alert|JIRA] send an email if an issue is an a given threshold of its due date (3 days before, on due date, every day after due date)
- [Alert|JIRA] send an email if an issue hasn't been updated for X days
- [Alert|JIRA] send an email if an issue makes more than 2 returns to "In Dev" status after review or functional review
- [Automate|Git+Github] on a deploy, generate a beautiful release note
- [Automate|JIRA+Github] issue in functional review and GO from product and tests are green => merge in develop
- [Automate|Slack+Google Calendar] Send the maintenance to-do list to whoever is in charge.

## Implementation

### Automate|Toggl+JIRA New time entry in Toggl => add workflow in JIRA

API request:
`https://toggl.com/reports/api/v2/details?user_agent=JobTomate (<dev@jobteaser.com>)&workspace_id=939576&page=5`

- Paginated: use `page` parameter

Processing rules:
- Identify new entries, if not updated for 2 hours, add the corresponding worklog to JIRA. (This allows an entry to be modified during 2 hours after its creation.)