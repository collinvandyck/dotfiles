#!/usr/bin/env bash

# {
#   "session_id": "0aab4ee1-1905-423e-ad69-715e4c037080",
#   "transcript_path": "/Users/collin/.claude/projects/-Users-collin--dotfiles/0aab4ee1-1905-423e-ad69-715e4c037080.jsonl",
#   "cwd": "/Users/collin/.dotfiles",
#   "hook_event_name": "SessionStart",
#   "source": "startup",
#   "model": "claude-opus-4-6"
# }

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.source')

case "$COMMAND" in
	"startup")
		#say "here we go"
		;;
	*)
		#say "foo ${COMMAND}"
		;;
esac
