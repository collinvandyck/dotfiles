# this file is zsh. unquoted array expansions don't word-split in zsh, and quoting ${path:#...} would join it into a
# single word, so SC2206 is noise here. SC2296 flags zsh expansion flags like ${(j.:.)x}.
# shellcheck disable=SC2206,SC2296

# toggles the shims in ~/.dotfiles/shims by putting them at the front of PATH. BROWSER also points at the open shim
# so tools that read it (e.g. aws sso login) go through the shim too. disable-shims restores the previous BROWSER.
#
# mise's precmd hook rebuilds PATH from __MISE_ORIG_PATH (its snapshot at activation, inherited by nested shells) and
# appends anything added since, so the snapshot gets the same edit or the shims end up behind /usr/bin.

_shims_dir="${HOME}/.dotfiles/shims"

enable-shims() {
	path=("${_shims_dir}" ${path:#${_shims_dir}})
	if [[ -n ${__MISE_ORIG_PATH-} ]]; then
		local -a orig=(${(s.:.)__MISE_ORIG_PATH})
		orig=("${_shims_dir}" ${orig:#${_shims_dir}})
		export __MISE_ORIG_PATH=${(j.:.)orig}
	fi
	if [[ ${BROWSER-} != "${_shims_dir}/open" ]]; then
		_shims_prev_browser="${BROWSER-}"
		export BROWSER="${_shims_dir}/open"
	fi
	rehash
}

disable-shims() {
	path=(${path:#${_shims_dir}})
	if [[ -n ${__MISE_ORIG_PATH-} ]]; then
		local -a orig=(${(s.:.)__MISE_ORIG_PATH})
		export __MISE_ORIG_PATH=${(j.:.)${orig:#${_shims_dir}}}
	fi
	if [[ ${BROWSER-} == "${_shims_dir}/open" ]]; then
		if [[ -n ${_shims_prev_browser-} ]]; then
			export BROWSER="${_shims_prev_browser}"
		else
			unset BROWSER
		fi
	fi
	unset _shims_prev_browser
	rehash
}
