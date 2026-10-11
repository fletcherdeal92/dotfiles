# Fresh zsh configuration
eval "$(starship init zsh)"

# Modern CLI aliases
alias ls="eza --icons"
alias ll="eza -l --icons"
alias la="eza -la --icons"
alias cat="bat"
alias find="fd"

# eza only reads ~/.config on macOS when told to
export EZA_CONFIG_DIR="$HOME/.config/eza"
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"

# fzf — Ctrl-R history, Ctrl-T files, Alt-C dirs (Severance palette)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border=rounded \
  --color=bg:-1,bg+:#1E222A,fg:#C5C8C6,fg+:#E5E9F0 \
  --color=hl:#8C9F82,hl+:#A3BE8C,info:#4C566A,border:#4C566A \
  --color=prompt:#8C9F82,pointer:#8C9F82,marker:#EBCB8B,spinner:#8C9F82,header:#81A1C1,gutter:-1"
source <(fzf --zsh)

# zoxide — `z <part of a path>` jumps to frequent directories
eval "$(zoxide init zsh)"

# Ghost-text suggestions from history (→ to accept)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#4C566A'
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting — must be sourced last
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_HIGHLIGHT_STYLES[command]='fg=#8C9F82'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#8C9F82'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#8C9F82'
ZSH_HIGHLIGHT_STYLES[function]='fg=#8C9F82'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#8C9F82,underline'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#BF616A'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#B48EAD'
ZSH_HIGHLIGHT_STYLES[path]='fg=#81A1C1,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#EBCB8B'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#EBCB8B'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#EBCB8B'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#8FBCBB'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#8FBCBB'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#4C566A'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#B48EAD'
