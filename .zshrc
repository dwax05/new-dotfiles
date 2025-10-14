#!/bin/zsh

# Set ZDOTDIR to keep Zsh config modular and in $XDG_CONFIG_HOME
export ZDOTDIR="$HOME/.config/zsh"

# Load environment and plugin setup
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/env"
source "$ZDOTDIR/.zplugins"
source "$ZDOTDIR/.fzf.zsh"

# Completion
autoload -Uz compinit
fpath+=~/.zfunc
zstyle ':completion:*' menu select
compinit

# Ruby via chruby
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
source /opt/homebrew/opt/chruby/share/chruby/auto.sh
chruby ruby-3.3.5

# Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# DevkitPro
export PATH="/opt/devkitpro/pacman/bin:$PATH"

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

export PATH=$PATH:/Users/dylanwax/.spicetify

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/dylanwax/.lmstudio/bin"
# End of LM Studio CLI section

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/dylanwax/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

