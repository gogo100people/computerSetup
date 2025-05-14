#!/bin/bash

# Check if the script is ACTUALLY running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script is intended to be run on macOS only."
    # Check for linux
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Use linux.sh instead."
    fi
    # Check for WSL
    if [[ "$OSTYPE" == "linux-gnu"* && $(uname -r) == *Microsoft* ]]; then
        echo "Use linux.sh instead."
    fi
    # Check for git-bash
    if [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]]; then
        echo "Use windows.cmd instead."
    fi
    exit 1
fi

which brew >/dev/null 2>&1
[[ $? -ne 0 ]] && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if which brew > /dev/null 2>&1; then
    # Detect system architecture
    if [[ $(uname -m) == "arm64" ]]; then
        # For Apple Silicon Macs (ARM64)
        export PATH="/opt/homebrew/bin:$PATH"
        eval "$(/opt/homebrew/bin/brew shellenv)"  # For Apple Silicon Macs
    else
        # For Intel Macs (x86_64)
        export PATH="/usr/local/bin:$PATH"
        eval "$(/usr/local/bin/brew shellenv)"  # For Intel Macs
    fi
fi

brew install jandedobbeleer/oh-my-posh/oh-my-posh stow git zsh \
    neovim fzf bat exa ripgrep
brew install --cask alacritty firefox

# Create the .dotfiles directory
mkdir -p "$HOME/.dotfiles"

# Move to the home directory
cd "$HOME" || exit 1

# Move all non-dot-dot hidden files into .dotfiles
for file in .[^.]*; do
    # Skip the .dotfiles dir itself if rerunning the script
    [[ -L "$file" ]] && continue
    [[ "$file" == ".dotfiles" ]] && continue
    mv "$file" "$HOME/.dotfiles"
done

# Go into the .dotfiles directory
cd "$HOME/.dotfiles" || exit 1

# Remove existing ignore file if present
[[ -f .stow-local-ignore ]] && rm .stow-local-ignore

# Write new ignore file
cat <<EOF > .stow-local-ignore
# Comments and blank lines are allowed.

RCS
.+,v

CVS
\.\#.+       # CVS conflict files / emacs lock files
\.cvsignore

\.svn
_darcs
\.hg

\.git
\.gitignore
\.gitmodules

.+~          # emacs backup files
\#.*\#       # emacs autosave files

^/README.*
^/LICENSE.*
^/COPYING

.git
EOF

# Remove any existing git repo
[[ -d .git ]] && rm -rf .git

# Initialize a new git repo
git init

[[ -f .zshrc ]] && rm .zshrc
touch .zshrc
cat <<EOF > .zshrc
if which brew > /dev/null 2>&1; then
    # Detect system architecture
    if [[ \$(uname -m) == "arm64" ]]; then
        # For Apple Silicon Macs (ARM64)
        export PATH="/opt/homebrew/bin:\$PATH"
        eval "\$(/opt/homebrew/bin/brew shellenv)"  # For Apple Silicon Macs
    else
        # For Intel Macs (x86_64)
        export PATH="/usr/local/bin:\$PATH"
        eval "\$(/usr/local/bin/brew shellenv)"  # For Intel Macs
    fi
fi

# Setup Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Zinit Plugins
zinit ice depth=1

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# Load completions
autoload -U compinit && compinit

bindkey -e

# Load Oh My Posh
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "\$(oh-my-posh init zsh)"
fi

alias ls='exa --icons --color=always'
alias cat='bat'
alias grep='rg'
alias df='df -h'
alias du='du -h'
alias ll='ls -l'
alias vim='nvim'
alias vi='nvim'
alias commit='git commit -' # Commit staging all changes

source $HOME/.shellsettings.sh
EOF

[[ -f .shellsettings.sh ]] && rm .shellsettings.sh
touch .shellsettings.sh
cat <<EOF > .shellsettings.sh
# This is the custom configuration for shells. Configure it as you like.




EOF

oh-my-posh font install

# Change the default browser to Firefox
if [[ $(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array | grep -c "org.mozilla.firefox") -eq 0 ]]; then
    echo "Setting Firefox as the default browser..."
    open -a "Firefox" --args --make-default-browser
fi

# Change the default terminal to Alacritty
if [[ $(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array | grep -c "org.alacritty") -eq 0 ]]; then
    echo "Setting Alacritty as the default terminal..."
    open -a "Alacritty" --args --make-default-browser
fi

# Stow the dotfiles
cd "$HOME/.dotfiles"
stow . # stow all

# Set the default shell to Zsh
if [[ "$SHELL" != *"/zsh" ]]; then
    chsh -s "$(which zsh)"
fi

