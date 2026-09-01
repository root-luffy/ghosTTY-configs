# Re-roll the Ghostty background image on every new shell (~5ms).
# The new pick shows up in the next window you open, or in this one via
# ctrl+shift+r. Source this from ~/.zshrc.
[[ -x "$HOME/.local/bin/ghostty-wallpaper" ]] && "$HOME/.local/bin/ghostty-wallpaper" >/dev/null 2>&1
alias gwall='ghostty-wallpaper'
