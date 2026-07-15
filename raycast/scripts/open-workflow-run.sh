#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Workflow Run
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "dropdown", "placeholder": "namespace", "data": [{"title": "scaffold.infra", "value": "scaffold.infra"}, {"title": "prod.infra", "value": "prod.infra"}, {"title": "prod.cp", "value": "prod.cp"}, {"title": "test.cp", "value": "test.cp"}] }
# @raycast.argument2 { "type": "text", "placeholder": "run id (defaults to clipboard)", "optional": true }

set -euo pipefail

namespace="${1:-}"
run_id="${2:-}"

if [[ -z "$run_id" ]]; then
	run_id="$(pbpaste | tr -d '\r\n')"
fi

if [[ -z "$run_id" ]]; then
	echo "Workflow ID required"
	exit 1
fi

encoded_run_id="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$run_id")"

open "https://cloud.temporal.io/namespaces/${namespace}/workflows?query=%60RunId%60%3D%22${encoded_run_id}%22"
