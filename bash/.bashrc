# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# enable color support of ls (eza überschreibt den Alias weiter unten, falls installiert)
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ===== Prompt =====
# Ozean-Prompt: janbah hellblau, thinkpad cyan, Pfad schaumweiß
PS1='\[\e[38;2;127;180;217m\]\u\[\e[38;2;232;241;248m\]@\[\e[38;2;86;182;194m\]\h\[\e[38;2;232;241;248m\]:\[\e[38;2;245;201;123m\]\w\[\e[0m\]\$ '
PROMPT_DIRTRIM=2

# ===== Verlauf =====
HISTSIZE=100000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups   # keine Duplikate, Befehle mit Leerzeichen davor werden nicht gespeichert
shopt -s histappend                # mehrere Terminals überschreiben sich nicht gegenseitig
# Befehle sofort in den Verlauf schreiben (nicht erst beim Schließen des Terminals)
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ===== Editor =====
# export ist wichtig, sonst sehen git & Co. die Variable nicht
export EDITOR=vim
export VISUAL=vim

# ===== Vim-Modus =====
# Steht auch in ~/.inputrc, hier zusätzlich, damit fzf unten
# seine Tasten (Strg+R, Strg+T, Alt+C) für den Vim-Modus einrichtet.
set -o vi
# Alt+h tippt ~/
bind -m vi-insert '"\eh": "~/"'
# Pfeil hoch/runter (Verlaufssuche) und Tab-Verhalten stehen in ~/.inputrc

# ===== Navigation =====
CDPATH=.:$HOME

# ===== Redmine =====
export REDMINE_URL="https://issues.saltation.de"
export REDMINE_API_KEY="$(secret-tool lookup service redmine 2>/dev/null)"

# ===== .NET / NuGet =====
# Paket: GitLab-NuGet-Credentials nur für den Aufruf aus dem Keyring laden
paket() {
  NUGET_GITLAB_USER="jbahlmann" \
  NUGET_GITLAB_TOKEN="$(secret-tool lookup service gitlab-nuget user janbah)" \
  dotnet paket "$@"
}

# NuGet-Publish: GitLab-Token nur für den Aufruf aus dem Keyring laden
publish_nuget() {
  NUGET_GITLAB_TOKEN="$(secret-tool lookup service gitlab-nuget-push user janbah)" \
  ./publish_nuget.sh "$@"
}

# ===== nvm =====
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ===== Tools =====
alias bat=batcat
alias fd=fdfind
if command -v eza >/dev/null; then
  alias ls='eza --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto'
fi

command -v lazygit >/dev/null && alias lg=lazygit

# yazi über "y" starten: beim Beenden landet die Shell im zuletzt besuchten Ordner
function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

# ===== fzf, zoxide & direnv (am Ende, nach set -o vi) =====
command -v fzf    >/dev/null && eval "$(fzf --bash)"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
# direnv: lädt/entlädt .envrc beim Betreten/Verlassen eines Ordners
command -v direnv >/dev/null && eval "$(direnv hook bash)"
