if [[ "$(uname -s)" == "Linux" ]]; then
  if [[ "$(uname -p)" == "aarch64" ]]; then
	  alias kc='sudo kubectl'
  fi
fi


