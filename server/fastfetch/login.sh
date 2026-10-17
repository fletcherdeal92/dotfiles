# Sourced from ~/.profile: show fastfetch on interactive SSH logins only.
case $- in *i*) ;; *) return 0 ;; esac
[ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && command -v fastfetch >/dev/null 2>&1 && fastfetch
