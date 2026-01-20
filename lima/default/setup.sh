#!/usr/bin/env bash

set -euo pipefail

# Commands to be run on a fresh default lima instance

lima sh -c 'curl https://mise.run | sh'
lima sudo snap install node --classic
lima sudo npm install -g @anthropic-ai/claude-code
#lima 'echo "eval \"$(/home/collin.linux/.local/bin/mise activate bash)\" >> /home/collin.linux/.bashrc"'
