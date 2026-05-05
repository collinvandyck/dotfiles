---
name: get-dynamic-config-details
description: Fetches the latest production dynamic config (DC) details for a particular feature.
disable-model-invocation: false
user-invocable: true
allowed-tools: Bash(~/code/temporal/temporal-utils/bin/get-dc-details)
argument-hint: "<DC name>"
---

This skill fetches the latest production DC for a feature.
It finds all of the cells and dynamic config settings for the feature.
It then fetches namespace details for each NS that has the DC enables.
It eventually writes the data to /tmp/dc-details.
It can take a while to run (maybe up to 5 minutes) but caches intermediate results to avoid redundant API calls.

Examples:

```shell
# get the SAA DC details
get-dc-details activity.enableStandalone

# bust cache and force results again
get-dc-details activity.enableStandalone --force
```

Do not use `--force` unless requested.
After the results are written, find the relevant CSV file.

