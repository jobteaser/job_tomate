# Development tips

## Searching for a custom field?

- Set `JIRA_USERNAME` and `JIRA_PASSWORD` environment variables.
- Open a local console with `bin/console`.
- Run `JSON.parse(JobTomate::Commands::JIRA::GetFields.run.body)`.
