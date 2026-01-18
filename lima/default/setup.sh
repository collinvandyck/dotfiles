#!/usr/bin/env bash

set -euo pipefail

# Commands to be run on a fresh default lima instance

if ! command -v mise &> /dev/null; then
	curl https://mise.run | sh
fi

