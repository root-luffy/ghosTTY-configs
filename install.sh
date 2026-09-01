#!/usr/bin/env bash
# Symlink this Ghostty setup into place. Anything already there is backed up
# rather than overwritten, and symlinking (not copying) means editing the live
# config edits the repo, so `git diff` shows what has drifted.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

link() {
	local from="$1" to="$2"
	mkdir -p "$(dirname "$to")"
	if [[ -e $to || -L $to ]]; then
		if [[ "$(readlink -f "$to")" == "$(readlink -f "$from")" ]]; then
			echo "  ok      $to"
			return
		fi
		mv "$to" "$to.bak-$STAMP"
		echo "  backed up $to -> $to.bak-$STAMP"
	fi
	ln -s "$from" "$to"
	echo "  linked  $to"
}

echo "ghostty config:"
link "$SRC/config" "$HOME/.config/ghostty/config"
link "$SRC/shaders/glow.glsl" "$HOME/.config/ghostty/shaders/glow.glsl"
link "$SRC/shaders/crt.glsl" "$HOME/.config/ghostty/shaders/crt.glsl"

echo "wallpaper tool:"
link "$SRC/bin/ghostty-wallpaper" "$HOME/.local/bin/ghostty-wallpaper"

echo "wallpaper images:"
link "$SRC/wallpapers" "$HOME/Pictures/ghostty"

echo "rotation timer:"
link "$SRC/systemd/ghostty-wallpaper.service" "$HOME/.config/systemd/user/ghostty-wallpaper.service"
link "$SRC/systemd/ghostty-wallpaper.timer" "$HOME/.config/systemd/user/ghostty-wallpaper.timer"
systemctl --user daemon-reload
systemctl --user enable --now ghostty-wallpaper.timer
echo "  timer enabled"

echo "zsh hook (re-roll on every new shell):"
ZSHRC="$HOME/.zshrc"
HOOK_LINE="source $SRC/zsh/wallpaper-hook.zsh"
if [[ -f $ZSHRC ]] && grep -qF "wallpaper-hook.zsh" "$ZSHRC"; then
	echo "  ok      $ZSHRC already sources the hook"
else
	printf '\n# Ghostty wallpaper: re-roll on every new shell\n%s\n' "$HOOK_LINE" >>"$ZSHRC"
	echo "  added   $HOOK_LINE -> $ZSHRC"
fi

echo
echo "Done. Open a new window (or a new shell) to see it."
echo "Drop more images in ~/Pictures/ghostty (-> $SRC/wallpapers) to add to the rotation."
echo "Missing ImageMagick? sudo pacman -S imagemagick"
