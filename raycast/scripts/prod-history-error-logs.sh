#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Prod History Error Logs
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Grafana
# @raycast.icon images/grafana.png
# @raycast.iconDark images/grafana-logo-iconDark.png
# @raycast.argument1 { "type": "text", "placeholder": "cluster", "optional": false }

CLUSTER="$1"
GRAFANA_HOST="grafana.tmprl-internal.cloud"
DATASOURCE_UID="e008932a-e9dc-4b7a-819f-68b662f3dc51"
DATASOURCE_TYPE="loki"
ORG_ID="1"
TIME_FROM="now-1h"
TIME_TO="now"
EXPR="{cluster=\"${CLUSTER}\", k8s_component=\"history\"} | json | level = \`error\`"
PANES=$(jq -n -c \
  --arg uid "$DATASOURCE_UID" \
  --arg type "$DATASOURCE_TYPE" \
  --arg expr "$EXPR" \
  --arg from "$TIME_FROM" \
  --arg to "$TIME_TO" \
  '{
    "prod-history-logs": {
      "datasource": $uid,
      "queries": [{
        "refId": "A",
        "expr": $expr,
        "queryType": "range",
        "datasource": { "type": $type, "uid": $uid },
        "editorMode": "code"
      }],
      "range": { "from": $from, "to": $to }
    }
  }')

ENCODED_PANES=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$PANES")
open "https://${GRAFANA_HOST}/explore?schemaVersion=1&panes=${ENCODED_PANES}&orgId=${ORG_ID}"

