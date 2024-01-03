Set-PSReadLineOption -EditMode Emacs

function gf { git fetch }
function gb { git branch }
function gst { git status }
function gl { git pull --rebase }
function gll { git log --pretty=oneline --abbrev-commit --decorate --graph }
function glla { git log --pretty=oneline --abbrev-commit --decorate --graph --all }
function gllc { gll --glob="refs/*/collin/*" --glob="refs/*/main" --glob="refs/*/master" }
function gcav { git add -A; git commit -v }

set-alias bat           get-content
set-alias vi            nvim
set-alias vim           nvim

