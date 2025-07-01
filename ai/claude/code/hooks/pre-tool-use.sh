#!/usr/bin/env bash

#  Example input
#
#  {
#    "session_id": "2975de7e-fec8-47fb-a6cd-2265d5eff570",
#    "transcript_path": "/Users/collin/.claude/projects/-Users-collin--dotfiles/2975de7e-fec8-47fb-a6cd-2265d5eff570.jsonl",
#    "tool_name": "Bash",
#    "tool_input": {
#  		"command": "head -20 /tmp/claude-hooks-pre-tool.log 2>/dev/null || echo \"Log file is empty\"",
#  		"description": "Check first 20 lines of log file"
#  	 }
#  }

cat >> /tmp/claude-hooks-pre-tool.log
