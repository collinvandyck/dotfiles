#!/usr/bin/env zsh

_PAYLOAD_FORMAT='
{
  "hook_event_name": "Status",
  "session_id": "abc123...",
  "transcript_path": "/path/to/transcript.json",
  "cwd": "/current/working/directory",
  "model": {
    "id": "claude-opus-4-1",
    "display_name": "Opus"
  },
  "workspace": {
    "current_dir": "/current/working/directory",
    "project_dir": "/original/project/directory"
  },
  "version": "1.0.80",
  "output_style": {
    "name": "default"
  },
  "cost": {
    "total_cost_usd": 0.01234,
    "total_duration_ms": 45000,
    "total_api_duration_ms": 2300,
    "total_lines_added": 156,
    "total_lines_removed": 23
  },
  "context_window": {
    "total_input_tokens": 15234,
    "total_output_tokens": 4521,
    "context_window_size": 200000,
    "used_percentage": 42.5,
    "remaining_percentage": 57.5,
    "current_usage": {
      "input_tokens": 8500,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 2000
    }
  }
}
'
input=$(cat)

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name // "—"')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // empty')
COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' | xargs printf "%.2f")
CONTEXT_REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // "—" | if type == "number" then round | tostring + "%" else . end')
SESSION_ID=$(echo "$input" | jq -r '.session_id // "—"')

echo "[$MODEL_DISPLAY] ⏰ ${CONTEXT_REMAINING} 💰 \$${COST_USD} 📁 ${CURRENT_DIR/#$HOME/~} -- ${SESSION_ID}"

