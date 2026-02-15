# ====================
# command line tool
# ====================

# fzf
source <(fzf --zsh)

# zoxide
eval "$(zoxide init zsh)"

# Yazi (enable yazi to enter directory on exit)
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# ====================
# Alias
# ====================
alias ls="eza --icons --colour=always"
alias cat="bat"
alias cd="z"
alias zz="z -"
alias nn="cd /Users/maverickchow/Library/Mobile\ Documents/iCloud\~md\~obsidian/Documents/Maverick\'s\ Obsidian\ Vault;nvim"


# ====================
# Programming stuff
# ====================
#
# Enable C programming tools in the .c-tools folder (IC)
source ~/.c-tools

# Enable Haskell environment
[ -f "/Users/maverickchow/.ghcup/env" ] && source "/Users/maverickchow/.ghcup/env"

# Java
export JAVA_HOME=$(/usr/libexec/java_home)

# Notes/MarkDown
export OBSIDIAN_PATH="/Users/maverickchow/Library/Mobile Documents/iCloud~md~obsidian/Documents/Maverick's Obsidian Vault"
export NOTEBOOK="/Users/maverickchow/Library/Mobile Documents/iCloud~md~obsidian/Documents/Maverick's Obsidian Vault"

# Enable LLVM
export PATH="/opt/homebrew/opt/llvm@18/bin:$PATH"
# export PATH="$HOME/bin:$PATH" # simlink clang++ from llvm18 to clang++-18 in ~/bin
# ln -s "$(brew --prefix llvm@18)/bin/clang++" ~/bin/clang++-18
#
# Added by Antigravity
export PATH="/Users/maverickchow/.antigravity/antigravity/bin:$PATH"

# ====================
# API keys
# ====================

source ~/api_keys/openai_key.sh

# ====================
# Starship
# ====================

eval "$(starship init zsh)"
