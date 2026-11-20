#!/usr/bin/env bash

# Shared helpers for the raycast scripts. Source it with:
#
#   . "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Where the most recently used cell is remembered between runs.
last_cell_file() {
	printf '%s' "${LAST_CELL_FILE:-$HOME/.last-cell}"
}

# Staging cells are remembered apart from prod cells so one never becomes the
# default for the prod scripts.
last_staging_cell_file() {
	printf '%s' "${LAST_STAGING_CELL_FILE:-$HOME/.last-staging-cell}"
}

# Where the staging scripts keep the test cells that test-cells lists, one per
# line, in its order.
staging_cells_file() {
	printf '%s' "${STAGING_CELLS_FILE:-$HOME/.staging-cells}"
}

# Sets the grafana variables, namespaces, and cell file for CELL_PROFILE, which
# is prod unless a staging wrapper script set it. Values that go into urls are
# already url-encoded. Source ~/.env first, since the namespaces come from it.
#
# For staging, only GRAFANA_ENV, PROM_DS, CH_DS, and LOKI_DS come from a
# known-good link. GRAFANA_THANOS_ENV follows GRAFANA_ENV, CH_VIS_DS reuses the
# staging clickhouse, and the infra DB is still prod's.
# shellcheck disable=SC2034
use_profile() {
	case "${CELL_PROFILE:-prod}" in
	prod)
		GRAFANA_ENV="prod"
		GRAFANA_THANOS_ENV="prod%20thanos"
		PROM_DS="af7fe237-211e-413e-9723-41a73886bcbb"
		CH_DS="aey7czk2sodtse"
		CH_VIS_DS="a1c8349c-753a-4a4c-b2b9-71e3f927e6cb"
		LOKI_DS="e008932a-e9dc-4b7a-819f-68b662f3dc51"
		INFRA_DB_NAME="Prod%2FInfraDB"
		INFRA_DB_DS="c8ea5458-e200-47da-aabc-eea36405a733"
		CP_NAMESPACES=("$TEMPORAL_CP_NAMESPACE" "$TEMPORAL_TEST_CP_NAMESPACE")
		INFRA_NAMESPACE="$TEMPORAL_INFRA_NAMESPACE"
		SUPPORT_HOST="cloud.temporal.io"
		CELL_FILE="$(last_cell_file)"
		;;
	staging)
		GRAFANA_ENV="dev%20thanos"
		GRAFANA_THANOS_ENV="dev%20thanos"
		PROM_DS="ef667c0e-d08c-4b40-9761-479514828632"
		CH_DS="bevsfyywc7hfka"
		CH_VIS_DS="bevsfyywc7hfka"
		LOKI_DS=""
		INFRA_DB_NAME="Prod%2FInfraDB"
		INFRA_DB_DS="c8ea5458-e200-47da-aabc-eea36405a733"
		CP_NAMESPACES=("$TEMPORAL_TEST_CP_NAMESPACE")
		INFRA_NAMESPACE="$TEMPORAL_TEST_INFRA_NAMESPACE"
		SUPPORT_HOST="staging.thundergun.io"
		CELL_FILE="$(last_staging_cell_file)"
		;;
	*)
		echo "Unknown CELL_PROFILE: $CELL_PROFILE" >&2
		exit 1
		;;
	esac
}

# Trims surrounding whitespace and prefixes a cell name with "s-" if it isn't
# already there, so " aw021 " and "s-aw021" both come out as "s-aw021".
normalize_cell() {
	local cell
	cell="$(trim "$1")"
	case "$cell" in
	"" | s-*) printf '%s' "$cell" ;;
	*) printf 's-%s' "$cell" ;;
	esac
}

# Resolves the profile and the cell for this run and assigns the cell to the
# global CELL. Pass the raycast argument. For prod, a blank argument reads the
# last cell used back from the profile's cell file, so "open the same cell
# again" needs no typing. Staging resolves its cell with resolve_staging_cell.
# Exits 1 when there's nothing to fall back on.
#
# The resolved cell is written back on exit, but only if the script succeeded —
# a run that bailed on a missing env var shouldn't rewrite the memory. Call it
# directly (use_cell "$1"), never in a command substitution, or the trap lands
# in a subshell that exits immediately.
use_cell() {
	use_profile
	local cell
	if [ "${CELL_PROFILE:-prod}" = staging ]; then
		cell="$(resolve_staging_cell "$1")"
	else
		cell="$(normalize_cell "$1")"
		if [ -z "$cell" ]; then
			cell="$(remembered_cell)"
		fi
	fi
	if [ -z "$cell" ]; then
		echo "Cell required (none given, and no last cell remembered)" >&2
		exit 1
	fi
	CELL="$cell"
	trap remember_cell EXIT
}

# Picks the staging cell for the raycast argument after refreshing the staging
# cells file from test-cells:
#
#   - A blank argument uses the last staging cell if test-cells still lists it,
#     and otherwise the first test cell.
#   - An argument that's a substring of a test cell uses the first one it
#     matches, so "aws" opens s-collin-261120-aws.
#   - Any other argument is used as given, after normalize_cell.
#
# When no test cells are known, a blank argument falls back to the last staging
# cell, then to CELL in ~/.envrc.
resolve_staging_cell() {
	local input cells last match
	refresh_staging_cells
	cells="$(staging_cells_file)"
	input="$(trim "$1")"

	if [ -n "$input" ]; then
		match="$(grep -F -m 1 -- "$input" "$cells" 2>/dev/null)"
		if [ -n "$match" ]; then
			printf '%s' "$match"
		else
			normalize_cell "$input"
		fi
		return
	fi

	last="$(remembered_cell)"
	if [ -s "$cells" ]; then
		if [ -n "$last" ] && grep -Fxq -- "$last" "$cells"; then
			printf '%s' "$last"
		else
			head -n 1 "$cells"
		fi
	elif [ -n "$last" ]; then
		printf '%s' "$last"
	else
		normalize_cell "$(envrc_cell)"
	fi
}

# Writes the test-cells output to the staging cells file. test-cells caches its
# list for a day, so this is usually a file read. A failed or empty run leaves
# the previous list in place. Raycast's PATH may not include test-cells, so it
# falls back to the temporal-utils checkout.
refresh_staging_cells() {
	local file cmd tmp
	file="$(staging_cells_file)"
	cmd="$(command -v test-cells || printf '%s' "$HOME/code/temporal/temporal-utils/bin/test-cells")"
	tmp="$(mktemp "$file.XXXXXX")" || return 0
	if "$cmd" >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
		mv "$tmp" "$file"
	else
		rm -f "$tmp"
	fi
}

# Prints the profile's last cell, normalized, or nothing if none is remembered.
remembered_cell() {
	local cell=""
	if [ -f "$CELL_FILE" ]; then
		IFS= read -r cell <"$CELL_FILE" || true
	fi
	normalize_cell "$cell"
}

# Parses CELL out of ~/.envrc rather than sourcing it, since the file may call
# direnv stdlib functions.
envrc_cell() {
	sed -nE 's/^[[:space:]]*(export[[:space:]]+)?CELL=["'\'']?([^"'\''[:space:]]*).*/\2/p' "$HOME/.envrc" 2>/dev/null | tail -n 1
}

# Opens a grafana link with auto-refresh on, so a dashboard left open in a tab
# keeps up with the cell instead of freezing at the moment it was opened.
open_grafana() {
	local url="$1"
	case "$url" in
	*\?*) open "$url&refresh=1m" ;;
	*) open "$url?refresh=1m" ;;
	esac
}

# Strips leading and trailing whitespace.
trim() {
	local s="$1"
	s="${s#"${s%%[![:space:]]*}"}"
	s="${s%"${s##*[![:space:]]}"}"
	printf '%s' "$s"
}

# EXIT trap installed by use_cell. Preserves the script's exit status.
remember_cell() {
	local status=$?
	[ "$status" -eq 0 ] || return "$status"
	printf '%s\n' "$CELL" >"$CELL_FILE"
	return "$status"
}
