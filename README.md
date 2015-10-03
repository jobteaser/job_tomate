# JobTomate

## Purpose

Automate as many things as possible in our development workflow.

## What is automated?

- JIRA
- Github
- Toggl
- Slack

## Implemented workflows

### Toggl and JIRA

- New time entry in Toggl => add worlog in JIRA

### Github and JIRA

- Merge a PR in develop, add the "Merged in develop" comment in JIRA.
- Creating a PR add a comment in the jira issue with the PR URL.

### JIRA

- Automatically assign the appropriate person when changing the issue status.
- In "maintenance", when the reviewer or developer field is empty, assigns the user.

### JIRA and Slack

- Send an alert to #maintenance to JobTeaser slack team if the maintenance board has more than 5 TODO: & WIP issues.
- Notify someone on Slack an issue has been assigned to oneself.
- Notify on Slack an user mentioned in a comment on JIRA.

## Worklows todolist

### Toggl and Slack

- Slack DM if no Toggl report more than 2 hours after a normal work day start

### JIRA and Slack

- Send a Slack DM to the developer if the JIRA is changed to status "In Review" without a PR in the comments.
- Send a Slack DM if an issue is an a given threshold of its due date (3 days before, on due date, every day after due date)
- Send a Slack DM if an issue hasn't been updated for X days
- Send a Slack DM if an issue makes more than 2 returns to "In Dev" status after review or functional review

### JIRA

- If there is a subtask, change its status to the same status than the task.

### JIRA and Github

- PR validated in review (`:+1:` in the comments), add a comment in JIRA and change the issue's status to "Functional Review".
- PR validated in review (`:-1:` in the comments), add a comment in JIRA (including the comment on the PR) and change the issue's status to "In Dev".
- On a deploy, update the JIRA issue status and fix version for deployed issues (based on PRs merged in the deployed commit)
- On a deploy, generate a beautiful release note
- Issue in functional review and GO from product and tests are green => merge in develop

### Slack and Calendar

- Send the maintenance to-do list to whoever is in charge.

## How to use

**Open a console locally**

```
bin/console
```

**Deploy to Heroku**

```
bin/deploy
```

The deployed code will run a web application that will handle webhooks (see `webhooks_handler.rb`).

A scheduled task must be setup too. Use Heroku's Scheduler plugin, setup the following code:

```
ruby script/process_toggl_reports.rb
```

**Run a console on Heroku**

```
heroku run bin/console
```

**Add a new user**

```
# In the console on Heroku

# Get the Toggl username
JobTomate::TogglClient.fetch_reports(Date.yesterday, Date.today).map{|e| e['user']}.uniq

# The JIRA password can be reset manually for a given user by a JIRA admin
JobTomate::User.create toggl_user: 'Toggl User', github_user: 'Github User', jira_username: 'JIRA username', jira_password: 'JIRA password'
```

**Reprocess older Toggl reports for a given user**

```
reports = JobTomate::TogglClient.fetch_reports(Date.parse("2015-07-01"), Date.today).select {|r| r['user'] == 'some-user' }
reports.map { |r| JobTomate::TogglProcessor.process_toggl_report(r) }
```

## Setup

### Required environment variables

```
APP_ENV=development
MONGODB_URI=mongodb://127.0.0.1:27017/job_tomate
TOGGL_API_TOKEN=REPLACE-ME
TOGGL_WORKSPACE_ID=REPLACE-ME
SLACK_WEBHOOK_URL=REPLACE-ME
JIRA_ISSUE_URL_BASE=https://someproject.atlassian.net/browse
JIRA_API_URL_PREFIX=https://someproject.atlassian.net/rest/api/2
JIRA_USERNAME=REPLACE-ME
JIRA_PASSWORD=REPLACE-ME
JIRA_DEFAULT_USERNAMES_FOR_FUNCTIONAL_REVIEW=some.user,another.user
JIRA_ACCEPTED_USERNAMES_FOR_FUNCTIONAL_REVIEW=some.other
```

### JIRA Webhook

You must setup a webhook on JIRA to trigger JIRA-related workflows. You can find this in Administration > System > Webhooks.

Here is the configuration to use:

- URL: `deployment-domain/webhooks/jira`
- Select "updated" issue events, on all issues (no filter)

### Slack Webhook

Setup a webhook integration on Slack. Any default will do since they are all overriden by JobTomate.

The webhook URL must be defined in the environment variables (`SLACK_WEBHOOK_URL`).
