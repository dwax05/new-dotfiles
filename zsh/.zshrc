#!/bin/zsh

# Set ZDOTDIR to keep Zsh config modular and in $XDG_CONFIG_HOME
export ZDOTDIR="$HOME/.config/zsh"

# Load environment and plugin setup
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/env"
source "$ZDOTDIR/.zplugins"

# Completion
autoload -Uz compinit
fpath+=~/.zfunc
zstyle ':completion:*' menu select
compinit

# Conda Initialization (from conda init)
if [ -f "/Users/dylanwax/miniconda3/etc/profile.d/conda.sh" ]; then
  . "/Users/dylanwax/miniconda3/etc/profile.d/conda.sh"
else
  export PATH="/Users/dylanwax/miniconda3/bin:$PATH"
fi

# Set tmux window title dynamically
# if [[ -n "$TMUX" ]]; then
#   precmd() {
#     tmux rename-window "$(basename "$PWD")"
#     local win_name=$(tmux display-message -p '#W')
#     print -Pn "\e]0;${win_name}\a"
#   }
# fi

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/dylanwax/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

