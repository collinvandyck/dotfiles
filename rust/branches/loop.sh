#!/usr/bin/env bash

exec watchexec -c reset \
    --restart \
    --wrap-process none \
    --stop-timeout 1s \
    cargo run --quiet --bin branches
