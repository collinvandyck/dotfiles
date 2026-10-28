---
name: jira
description: Conventions for working with Jira through the Atlassian MCP — creating, editing, or searching tickets, adding them to a sprint, and writing descriptions or comments. Use whenever the user asks to create, update, or find a Jira ticket, pastes an atlassian.net link, or mentions a ticket key like ABC-1234.
---

# Jira

Practical conventions for driving Jira through the Atlassian MCP tools. More Jira workflows will be added over time.

## Defaults

- **Default project:** `CDS`.

## Adding a ticket to the current sprint

Sprint is a custom field (`customfield_<n>`, where `<n>` varies by site). It takes the numeric sprint id, not the name. Find the field id with `getJiraIssueTypeMetaWithFields` (`requiredFieldsOnly: false`), or by fetching one sprint ticket with `fields: ["*all"]` and looking for the array of `{id, name, state}` objects.

1. Find the active sprint id from my open-sprint tickets: `assignee = currentUser() AND sprint in openSprints()`, requesting `fields: ["summary", "<sprint field>"]`. Pick the entry with `state: active`.
2. Pass it at creation: `additional_fields: {"<sprint field>": <id>}`.
3. Confirm with `key = <new key> AND sprint in openSprints()`. The create response does not echo the sprint field.

Always pass a narrow `fields` list to `searchJiraIssuesUsingJql`. The default field set includes full descriptions, and a sprint's worth of tickets overflows the tool output.

## Writing descriptions and comments

### Links

Bare URLs in markdown content do not reliably become clickable links. Always give a link text.

- **Markdown:** `[Metering thread](https://...)`.
- **ADF (most reliable):** pass `contentFormat: "adf"` and a `doc` whose link text carries a link mark:

```json
{"type": "text", "text": "Metering thread", "marks": [{"type": "link", "attrs": {"href": "https://..."}}]}
```

Prefer ADF when a description has several links or when the user has already asked for a fix. Reads come back as markdown regardless of `responseContentFormat`, so a read-back cannot confirm that a link rendered. Ask the user to check it in the browser if it matters.

### Style

Follow the user's writing style and the `writing-clearly-and-concisely` skill. Keep descriptions short: a problem paragraph, a `Scope` list, and a `References` list of linked sources (Slack threads, PRs, dashboards).
