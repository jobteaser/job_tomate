# Debugging

## Example for issue #94

### Description of the issue

The issue is that on `pull_request` Github webhooks, if a corresponding Jira issue is identified using the branch name, the Jira should be updated with a comment including a link to the pull request.

This doesn't work anymore.

### Fix walkthrough

First, search in the prodution application's database the most recent stored webhook matching the scenario:

**Retrieve the production database locally**

```
bin/dump_production_to_local
```

**Run the console**

```
bin/console
```

**Retrieve the stored webhook**

```
raw_webhook = JobTomate::Data::StoredWebhook.where({"headers.HTTP_X_GITHUB_EVENT" => "pull_request"}).order_by(:created_at.asc).last
```

**Running the webhook**

```
JobTomate::Triggers::Webhooks::Github.new.run_events(raw_webhook.value)
```
