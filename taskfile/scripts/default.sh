#!/usr/bin/env bash

# This is the default task that runs. It should be non-destructive because
# it can be invoked from anywhere that does not already have a taskfile.

set -e

if [[ -x "Cargo.toml" ]]; then
	case $1 in
		**)
			cargo run $@
			;;
	esac
fi

