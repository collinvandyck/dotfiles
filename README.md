# Overview

This dotfiles is reponsible for provisioning my standard environment.

# Warning

The `git/.gitconfig` file gets symlinked to `~/.gitconfig` which has my own
name/email address for commits, so if you do decide to use this repo please fork
it and change those values.

# Usage

If you want to bootstrap your own env, it's recommended to fork this repo so
that you can make your own changes over time. Most importantly, change the
values in `git/.gitconfig`  to match your own.

```sh
git clone ${YOUR_FORK} ~/.dotfiles
cd .dotfiles
# IMPORTANT
vi ~/.dotfiles/git/.gitconfig #=> change name and email
./install-all
```
Once you're done installing, start a new shell and you're good to go. Youc an
always trigger the dotfiles uppdates by running:

```sh
update
```

This will keep your apt and brew dependencies up to date when run periodically.

