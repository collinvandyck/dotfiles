# Overview

This dotfiles is reponsible for provisioning my standard environment.

# Warning

The `git/.gitconfig` file gets symlinked to `~/.gitconfig` which has my own
name/email address for commits, so if you do decide to use this repo please fork
it and change those values.

# Usage

If you want to bootstrap your own env, it's recommended to fork this repo so
that you can make your own changes over time. However, it's not necessary, and
some configuration can be overridden through the use of environment files.

    % git clone https://github.com/collinvandyck/dotfiles.git ~/.dotfiles
    cd .dotfiles
    ./install-all

Once you're done installing, you can run the dotfiles installs again by using

    % update

This will keep your apt and brew dependencies up to date when run periodically.

# Neovim

My neovim setup is included in this repo and after the first install you should
probably run the following to get the neovim plugins setup:

    % nvim +PlugInstall


