# JobTomate

[![Build Status](https://travis-ci.org/jobteaser/job_tomate.svg?branch=master)](https://travis-ci.org/jobteaser/job_tomate)
[![Code Climate](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/badges/d4a9abf44cad651805e5/gpa.svg)](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/feed)
[![Test Coverage](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/badges/d4a9abf44cad651805e5/coverage.svg)](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/coverage)

## Purpose

Automate as many things as possible in our development workflow.

## To what is it connected?

- JIRA
- Github
- Toggl
- Slack (and bot)

## Workflows

Trigger | Event | Action | Status
------- | ----- | ------ | ------
Scheduled task | **Toggl** new time entry | **JIRA** add worklog on matching issue | DONE
Webhook | **Github** pull request opened | **JIRA** add comment on matching issue (branch named `jt-xyz-...`) | DONE
Webhook | **Github** pull request closed | **JIRA** add comment on matching issue (indicate if merged or not) | DONE
Webhook | **Github** status updated | The author of the update (e.g. Codeclimate analyze, CircleCI build) is notified on Slack | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the developer | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the reviewer | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the feature owner | DONE
Webhook | **JIRA** updated issue **assignee** | **Slack** notify the assignee | DONE
Webhook | **JIRA new comment** on issue | **Slack** notify the mentioned user(s) | DONE

## How to use

### Start dependencies (MongoDB)

```
docker-compose up -d
```

### Open a console locally

```
bin/console
```

NB: by default in non-production environments (see `RACK_ENV` environment variable), the `JIRA_DRY_RUN` is set to `"true"` to prevent JIRA API calls with effects (e.g. update, delete).

### Deploy to Heroku

```sh
# Staging
bin/set_env_staging
bin/deploy_staging

# Production
bin/set_env_production
bin/deploy_production
```

The deployed code will run a web application that will handle webhooks (see `triggers/webhooks.rb`).

Scheduled tasks must be setup for _tasks_ triggers (`triggers/tasks`). Using Heroku's Scheduler plugin, setup the following recurring task:

- `bin/run_task fetch_toggl_reports`: every 1 hour is fine

Some maintenance scripts must be scheduled too (Heroku's Scheduler plugin is fine too):

- `script/cleanup_stored_webhooks_and_requests`: every day

### Run a console on Heroku

```
heroku run bin/console -a <APP-NAME>
```

### Dump the production database

_NB: this assumes you have deployed to Heroku_

```
bin/dump_production_to_local
bin/dump_production_to_staging
```

### Add a new user

If the user started using Toggl, some `TogglEntry` records should be pending for this user. We can use them to find the user's Toggl username. We also need to process them after the user has been created.

_In an application console:_

```
# Get the Toggl username
JobTomate::Data::TogglEntry.where(status: "pending").all.map(&:toggl_user).uniq
=> ["New User"]

# The JIRA password can be reset manually for a given user by a JIRA admin
JobTomate::Data::User.create toggl_user: 'Toggl User', github_user: 'Github User', jira_username: 'JIRA username', jira_password: 'JIRA password', developer_backend: true, developer_frontend: false, jira_reviewer: true, jira_feature_owner: false, jira_functional_reviewer: false, slack_username: 'Slack User'
```

**Reprocess older Toggl reports for a given user**

All unprocessed Toggl reports are stored as `Data::TogglEntry` records with the status `"pending"`. Use the following task to process them:

```
bin/run_task process_pending_toggl_entries
```

## Setup

### Required environment variables

See `.env.example` file.

### JIRA Webhook

You must setup a webhook on JIRA to trigger JIRA-related workflows. You can find this in Administration > System > Webhooks.

Here is the configuration to use:

- URL: `https://<your-domain>/webhooks/jira`
- Select "updated" issue events, on all issues (no filter)

### Github Webhook

For each repository that needs to be connected to JobTomate, setup the webhook like this:

- URL: `https://<your-domain>/webhooks/github`
- Content type: select "application/json"
- Select "Send me everything"

### Slack Webhook

Setup a webhook integration on Slack. Any default will do since they are all overriden by JobTomate. The webhook URL must be defined in the environment variables (`SLACK_WEBHOOK_URL`).

## Troubleshooting

### Pending Toggl entries

Use this script to analyze reasons for pending Toggl entries:

```
ruby script/analyze_pending_toggl_entries.rb
```

## Contributing

- Check the [issues](https://github.com/jobteaser/job_tomate/issues).
- Read the doc: 
  - [architecture](https://github.com/jobteaser/job_tomate/tree/master/doc/architecture.md),
  - [howtos](https://github.com/jobteaser/job_tomate/tree/master/doc/howtos.md),
  - [testing](https://github.com/jobteaser/job_tomate/tree/master/doc/testing.md),
  - [tips](https://github.com/jobteaser/job_tomate/tree/master/doc/development_tips.md).

