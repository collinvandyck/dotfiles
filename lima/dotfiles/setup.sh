#!/usr/bin/env bash

set -euo pipefail

INST=dotfiles

bail() { echo "$*" >&1; exit 1; }

if limactl list $INST &>/dev/null; then
	[[ $# -gt 0 && "$1" = "--force" ]] || bail "$INST vm already exists. use --force to recreate"
	limactl delete $INST -f
fi

limactl create --name $INST \
	template:default \
	--set '.user.name = "collin"'  \
	--set '.user.home = "/home/collin"' \
	--yes
limactl start $INST --mount-none

(
	tmpdir=$(mktemp -d)
	trap 'rm -rf "$tmpdir"' EXIT
	mkdir -p $tmpdir/collin.linux/.ssh/
	limactl copy -r default:/home/collin.linux/.ssh $tmpdir/collin.linux/.ssh/
	limactl copy -r $tmpdir/collin.linux/.ssh/ $INST:/home/collin/
)

lima() { command limactl shell $INST "$@"; }

lima sh -c 'if ! test -e ~/.dotfiles; then cd ~ && git clone git@github.com:collinvandyck/dotfiles.git ~/.dotfiles; fi'
lima sh -c 'cd ~/.dotfiles && git pull && ./install-all'

limactl restart $INST
limactl shell $INST
