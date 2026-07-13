#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Workflow
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "dropdown", "placeholder": "namespace", "data": [{"title": "scaffold.infra", "value": "scaffold.infra"}, {"title": "prod.infra", "value": "prod.infra"}, {"title": "prod.cp", "value": "prod.cp"}, {"title": "test.cp", "value": "test.cp"}] }
# @raycast.argument2 { "type": "text", "placeholder": "workflow id (defaults to clipboard)", "optional": true }

set -euo pipefail

namespace="${1:-}"
workflow_id="${2:-}"

if [[ -z "$workflow_id" ]]; then
	workflow_id="$(pbpaste | tr -d '\r\n')"
fi

if [[ -z "$workflow_id" ]]; then
	echo "Workflow ID required"
	exit 1
fi

encoded_workflow_id="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$workflow_id")"

open "https://cloud.temporal.io/namespaces/${namespace}/workflows/${encoded_workflow_id}"
