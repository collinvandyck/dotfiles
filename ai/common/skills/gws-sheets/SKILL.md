---
name: gws-sheets
description: Use when creating, reading, writing, or formatting Google Sheets via gws CLI — avoids python3 one-liners and permission prompts for JSON parsing
allowed-tools: Bash(*/gws-sheets *)
---

# Google Sheets Wrapper

Wraps `gws sheets` operations with clean JSON output, keyring stderr filtering, and built-in JSON extraction so you don't need ad-hoc python3 scripts.

## Prerequisites

`gws` must be authenticated with the file backend:
```bash
export GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file
gws auth login
```

## Commands

### Create a spreadsheet
```bash
~/.claude/skills/gws-sheets/bin/gws-sheets create "My Title" "Sheet1,Sheet2,Sheet3"
```
Returns `{ "spreadsheetId": "...", "spreadsheetUrl": "..." }`.

### List sheet IDs (needed for formatting)
```bash
~/.claude/skills/gws-sheets/bin/gws-sheets get-sheet-ids <spreadsheet-id>
```
Returns `SheetName=12345` pairs, one per line.

### Read computed values
```bash
~/.claude/skills/gws-sheets/bin/gws-sheets get-values <spreadsheet-id> "Sheet1!A1:D10"
```

### Read raw formulas
```bash
~/.claude/skills/gws-sheets/bin/gws-sheets get-formulas <spreadsheet-id> "Sheet1!A1:D10"
```

### Write values from a JSON file
```bash
~/.claude/skills/gws-sheets/bin/gws-sheets update-values <spreadsheet-id> "Sheet1!A1:C5" /tmp/data.json
```
The JSON file should have `{"values": [[...]]}` format. Values starting with `=` are interpreted as formulas. Prefix with `'` to force text.

### Apply formatting from a JSON file
```bash
~/.claude/skills/gws-sheets/bin/gws-sheets batch-update <spreadsheet-id> /tmp/format.json
```
The JSON file should have `{"requests": [...]}` format using the Sheets batchUpdate API.

### Look up API schema
```bash
~/.claude/skills/gws-sheets/bin/gws-sheets schema sheets.spreadsheets.batchUpdate
```

## Workflow

1. Use the Write tool to create JSON files in `/tmp/` (values, formatting requests)
2. Use this script to send them to the Sheets API
3. Use `get-values` / `get-formulas` to verify

This avoids shell escaping issues with inline JSON and eliminates python3 permission prompts.

## Dry run

All commands support `--dry-run` to show what would execute without calling the API.
