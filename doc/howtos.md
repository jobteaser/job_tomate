# How-tos

## How to improve an existing workflow

Say we want to add the branch name in the JIRA comment added when creating a new pull request ([issue #21](https://github.com/jobteaser/job_tomate/issues/21)).

### 1. Create the feature branch

Since we're on issue #21, create a branch prefixed with `issue#21-`, for example `issue#21-pull-request-jira-branch-name`. Be sure to branch from a fresh `master`.

### 2. Find and update the corresponding test(s)

- Tests are grouped around the _source_ trigger. Since our trigger is a Github pull request, we'll look into `spec/acceptance/github`. We find a matching spec: `pull_request_opened_spec`.
- By reading the test file, we find the test we need to update: `opened pull request related to JIRA issue adds a comment on the JIRA with the PR link`.
- We update the test to add the new expectation. We'll have a look at the used fixture. We can identify it through this call: `receive_stored_webhook(:github_pull_request_opened_jira_related)`.
- So the corresponding fixture file is: `spec/support/fixtures/stored_webhooks/github_pull_request_opened_jira_related.yml`.
- From the fixture, we can find that the branch for the pull request is `jt-1234-create-crawler`. So we change the expected comment by adding ` - branch: jt-1234-create-crawler`.

### 3. Find and update the corresponding implementation

Now that the test has been updated, the build is red and we need to fix the implementation. Let's find where:

- The workflow is related to a Github trigger, which is webhook. The starting point is `Triggers::Webhooks::Github`. Our workflow already exists, so we should not have to change it.
- This event is triggered for a new pull request, so we can find it easily: `Events::Github::PullRequestOpened`.
- By looking at the `PullRequestOpened` event, we can see the action corresponding to this workflow is `Actions::JIRAAddCommentOnGithubPullRequestOpened`. Our change will be there.
- This action is simply a call to `Commands::JIRA::AddComment` with appropriate parameters. Just updating the parameters will do the trick. We just add ` - branch: #{pull_request.branch}`.
- Did this work? Not yet, because the `#branch` method was not defined on `Values::PullRequest`. Since the `data` attribute of the `Values::PullRequest` is simply the content of the `pull_request` attribute of the Github webhook's payload, it's easy to add the method.
- You're done!
- NB: In fact, we used `Values::PullRequest#head_ref` which already exists and returns the expected value, instead of creating a new alias method.

Check the corresponding [pull request](https://github.com/jobteaser/job_tomate/pull/34) for the code!

### 4. Push and create pull request

Push your branch and go to Github to create the matching pull request. Link the fixed issue in the pull request's description, and wait for your tests to be green.


## How to create a new workflow

We want to add a workflow notifying a pull request's submitter that the status of a pull request has been updated by an external service ([issue 26](https://github.com/jobteaser/job_tomate/issues/26)). The Github webhook trigger with the `"status"` Github event will help us with this workflow.

### 1. Find a stored webhook and build a fixture for the test

- We start by retrieving the production database locally with `bin/dump_production_to_local`.
- This enables us to investigate the stored webhooks and try to find one matching our case.
- In the application's console (`bin/console`), we find the stored webhook and store it as a fixture:

```
# Retrieve a matching webhook
webhook = JobTomate::Data::StoredWebhook.order(:created_at.asc).select do |w|
  w.headers["HTTP_X_GITHUB_EVENT"] == "status"
end.last

# Make a fixture from it
webhook.write_to_fixture(:github_status_update)
```

**NB: you must anonymize the content of the fixture before committing it!**

### 2. Create a new acceptance test

Now that we have the appropriate fixture, we'll write the corresponding test. Since the workflow is triggered by the `status` Github event, we'll add a `spec/acceptance/github/status_spec.rb` file.

To execute the fixture webhook in the spec, we can use `receive_stored_webhook(:github_status)`. In our test, we'll be expecting a request to Slack. To help mocking it, we can use one of the `WebmockHelpers` module methods. The `stub_slack_send_message_as_job_tomate(text, channel)` seems really pertinent. The rest? Well, it's simple Ruby-testing as usual!

### 3. Write the implementation

When your test has been written, your build should be red. Time to write the implementation!
