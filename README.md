# Overview

This dotfiles is reponsible for provisioning my standard environment.

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

# Customization

My defaults are in the `.env.dist` environment file. You can create your own
`.env` file in the same directory. Note that the `.env` file is ignored by git.

    % cat .env.dist
    GIT_USER_NAME="Collin Van Dyck"
    GIT_EMAIL="collinvandyck@gmail.com"

You should at the least set your own variables here so that you don't commit as
me :)

# Neovim

My neovim setup is included in this repo and after the first install you should
probably run the following to get the neovim plugins setup:

    % nvim +PlugInstall


