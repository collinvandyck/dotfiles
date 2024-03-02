New-Item -Force -ItemType SymbolicLink -Path "$env:LOCALAPPDATA\nvim" -Target "$HOME\.dotfiles\nvim"
New-Item -Force -ItemType SymbolicLink -Path "$HOME\.gitconfig" -Target "$HOME\.dotfiles\git\.gitconfig"
New-Item -Force -ItemType SymbolicLink -Path "$HOME\.gitignore_global" -Target "$HOME\.dotfiles\git\.gitignore_global"
