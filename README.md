# JobTomate

[![Build Status](https://travis-ci.org/jobteaser/job_tomate.svg?branch=master)](https://travis-ci.org/jobteaser/job_tomate)
[![Code Climate](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/badges/d4a9abf44cad651805e5/gpa.svg)](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/feed)
[![Coverage Status](https://coveralls.io/repos/github/jobteaser/job_tomate/badge.svg?branch=master)](https://coveralls.io/github/jobteaser/job_tomate?branch=master)

## Purpose

Automate as many things as possible in our development workflow.

## To what is it connected?

- JIRA
- Github
- Toggl
- Slack ( and bot)

## Workflows

Trigger | Event | Action | Status
------- | ----- | ------ | ------
Scheduled task | **Toggl** new time entry | **JIRA** add worklog on matching issue | DONE
Webhook | **Github** pull request opened | **JIRA** add comment on matching issue (branch named `jt-xyz-...`) | DONE
Webhook | **Github** pull request closed | **JIRA** add comment on matching issue (indicate if merged or not) | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the developer | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the reviewer | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the feature owner | DONE
Webhook | **JIRA** updated issue **assignee** | **Slack** notify the assignee | DONE
Webhook | **JIRA new comment** on issue | **Slack** notify the mentioned user(s) | DONE
Webhook | **JIRA** updated issue **status** | **JIRA** assign the appropriate person | DONE

### Other ideas

- Send a Slack DM to the developer if the JIRA is changed to status "In Review" without a PR in the comments.
- Send a Slack DM if an issue is an a given threshold of its due date (3 days before, on due date, every day after due date)
- Send a Slack DM if an issue hasn't been updated for X days
- Send a Slack DM if an issue makes more than 2 returns to "In Dev" status after review or functional review
- JIRA: if there is a subtask, change its status to the same status than the task.
- PR validated in review (`:+1:` in the comments), add a comment in JIRA and change the issue's status to "Functional Review".
- PR validated in review (`:-1:` in the comments), add a comment in JIRA (including the comment on the PR) and change the issue's status to "In Dev".
- On a deploy, update the JIRA issue status and fix version for deployed issues (based on PRs merged in the deployed commit)
- On a deploy, generate a beautiful release note
- Issue in functional review and GO from product and tests are green => merge in develop
- Using the maintenance calendar, send the maintenance to-do list to whoever is in charge.

## How to use

**Open a console locally**

```
bin/console
```

**Deploy to Heroku**

```sh
# Staging
bin/set_env_staging
bin/deploy_staging

# Production
bin/set_env_production
bin/deploy_production
```

The deployed code will run a web application that will handle webhooks (see `webhooks_handler.rb`).

A scheduled task must be setup too. Using Heroku's Scheduler plugin, setup the following recurring task:

```
bin/run_task fetch_toggl_reports
```

**Run a console on Heroku**

```
heroku run bin/console -a <APP-NAME>
```

**Add a new user**

**TO BE UPDATED**

```
# In the console on Heroku

# Get the Toggl username
require 'job_tomate/commands/toggl/fetch_reports'
reports = JobTomate::Commands::Toggl::FetchReports.run(Date.yesterday, Date.today).map{|e| e['user']}.uniq

# The JIRA password can be reset manually for a given user by a JIRA admin
JobTomate::Data::User.create toggl_user: 'Toggl User', github_user: 'Github User', jira_username: 'JIRA username', jira_password: 'JIRA password'
```

**Reprocess older Toggl reports for a given user**

**TO BE UPDATED**

```
require 'job_tomate/commands/toggl/fetch_reports'
require 'job_tomate/commands/toggl/process_reports'
reports = JobTomate::Commands::Toggl::FetchReports.run(3.days.ago, Date.today).select {|r| r['user'] == 'some-user' }
reports.map { |r| JobTomate::Commands::Toggl::ProcessReports.process_toggl_report(r) }
```

## Setup

### Required environment variables

```
RACK_ENV=development
MONGODB_URI=mongodb://127.0.0.1:27017/job_tomate
TOGGL_API_TOKEN=REPLACE-ME
TOGGL_WORKSPACE_ID=REPLACE-ME
SLACK_WEBHOOK_URL=REPLACE-ME
JIRA_API_URL_PREFIX=https://someproject.atlassian.net/rest/api/2
JIRA_USERNAME=REPLACE-ME
JIRA_PASSWORD=REPLACE-ME
```

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

## Contributing

Check the issues.

### Overall architecture

JobTomate is built on a set of components that interact together to perform workflows:

#### Actions

#### Commands

#### Data

#### Events

#### Triggers

#### Values

### Architecture decisions

#### Using acceptance tests only

Except some specific cases for which unit tests may be helpful (`Commands::JIRA::Support::Client` and `Commands::Slack::SendMessage`), only acceptance tests are used.

Why has this approach been chosen?
  - It gives more freedom to change the implementation of underlying components, without having a lot of intermediate tests to be updated in the meanwhile.
  - The purpose of JobTomate is essentially to perform calls to external services in response to events triggered by other external services, so performing the tests at the level the nearer to these services felt right.
  - JobTomate will not be provided without actual workflows which will be acceptance-tested. Testing these workflows also ensures the underlying components are tested. Unit-testing the components would only provide a second and extraneous layer of tests.
