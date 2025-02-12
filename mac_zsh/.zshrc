# ====================
# p10k
# ====================

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ====================
# command line tool
# ====================

# fzf
source <(fzf --zsh)

# zoxide
eval "$(zoxide init zsh)"


# Enable C programming tools in the .c-tools folder (IC)
source ~/.c-tools

# ====================
# Alias
# ====================
alias ls="eza --icons --colour=always"
alias cat="bat"
alias cd="z"
alias zz="z -"


# ====================
# Language specific configs
# ====================

# Enable Haskell environment
[ -f "/Users/maverickchow/.ghcup/env" ] && source "/Users/maverickchow/.ghcup/env"

# Java
export JAVA_HOME=$(/usr/libexec/java_home)

# ====================
# API keys
# ====================

source ~/api_keys/openai_key.sh
