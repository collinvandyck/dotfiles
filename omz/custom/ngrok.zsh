#export LESS='-R --incsearch'
export NGROK_LOGS_PAGER="lnav"

export BAT_STYLE="changes"
export LESS='-R'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export PAGER='less -RX' # -X turns off the screen clearing function
export RIPGREP_CONFIG_PATH=~/.ripgrep.conf

alias kc='kubectl --kubeconfig /etc/ngrok/devenv.yaml --namespace controlplane'
alias kd='kubectl --kubeconfig /etc/ngrok/devenv.yaml --namespace us'
alias n='cd ~/ngrok'
alias nn='cd ~ && nvim +":OpenSession ngrok"'
export GIT_GEN="':!*.pb.go' ':!*.sql.go' ':!**/gen/**'"
alias ndi='nd go install nd'
alias amend='git commit --amend'

function add-gen-errors() {
	git add 'go/lib/ee/**'
	git add '**/gen/errors/**'
	git add '**/gen/error-code/**'
}

function add-gen-proto() {
	git add '**/*.pb.go'
	git add '**/rpx_mocks.go'
	git add '**/gen/proto/**'
}

function add-gen-db() {
	git add '**/*.sql.go'
}

function delete_node_modules() {
	rm -rf  \
		node_modules \
		.cache/node/node_modules \
		config/node_modules \
		js/node_modules \
		py/ngrok/web/node_modules
}

function rgig() {
	command rg -g '*.go' --heading "$@"
}

#####
# TODO: vvv these should probably become functions at some point so that we can re-use the exclusions
#####

# git diff no generated [files]
alias gdng="gd -w \$(git merge-base @ origin/master) ':!*.pb.go' ':!*.sql.go' ':!**/gen/**' ':!**/query/db.go' ':!**/testrpx/**'"
# git diff no generated [files] --stat
alias gdngs="gd -w \$(git merge-base @ origin/master) --stat ':!*.pb.go' ':!*.sql.go' ':!**/gen/**' ':!**/query/db.go' ':!**/testrpx/**'"

function testout() {
	cat | tee /tmp/test.out
}

function logs() {
	local target="${@}"
	case $target in 
	epr)
		target="endpoint.resolver"
		;;
	esac
	ne svc logs $target -f
}

function deploy() {
	local target="${@}"
	case $target in 
	epr)
		target="endpoint.resolver"
		;;
	esac
	nd svc deploy $target --wait && status $target
}

function status() {
	local target="${@}"
	case $target in 
	epr)
		target="endpoint.resolver"
		;;
	esac
	watch nd svc status $target
}

