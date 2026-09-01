# ghosTTY-configs

A [Ghostty](https://ghostty.org) setup built around one idea: a real wallpaper
behind the terminal that rotates on its own and never fights the text.

- **Neon Tokyo** palette, FantasqueSansM with Victor Mono italics
- **Neon bloom shader**, optional (`shaders/glow.glsl`, off by default — see below)
- **`ghostty-wallpaper`** — picks a random background image, dims it to a
  guaranteed-readable level, and applies it to already-open windows

## Contents

```
config                      main Ghostty config
shaders/glow.glsl           subtle neon bloom on bright text (off by default)
shaders/crt.glsl            retro CRT alternative (off by default)
bin/ghostty-wallpaper       the wallpaper tool
wallpapers/                 the curated image set, included so this works out of the box
systemd/*.service, *.timer  rotates the wallpaper every 5 minutes (Linux)
launchd/*.plist             rotates the wallpaper every 5 minutes (macOS)
zsh/wallpaper-hook.zsh      re-rolls on every new shell
```

## Install

```sh
./install.sh
```

That's the whole setup — it's meant to work immediately on a fresh clone:

- symlinks `config` and the shaders into `~/.config/ghostty`
- symlinks `bin/ghostty-wallpaper` into `~/.local/bin`
- symlinks `wallpapers/` to `~/Pictures/ghostty`, so the rotation has images
  from the first roll — no manual step needed
- enables the rotation timer — a systemd user timer on Linux, a launchd agent
  on macOS (`install.sh` detects which via `uname`)
- adds a line to `~/.zshrc` that re-rolls on every new shell (skipped if
  already present)

Anything already at one of those paths is backed up first, as
`<name>.bak-<timestamp>`, never overwritten. Symlinking (not copying) also
means editing the live config edits the repo directly, so `git diff` always
shows what's actually changed.

Needs `imagemagick` for the brightness work (`brew install imagemagick` on
macOS, or your Linux package manager). Nothing else to install — live reload
uses `kill -USR2` (a signal Ghostty itself has handled since 1.2), which needs
only `pgrep`/`kill`, already on both platforms. Open a new terminal window
after installing.

**Linux and macOS both work**, including macOS's stock `/bin/bash` (nothing
here needs bash 4). The only platform-specific pieces are the rotation timer
(systemd vs. launchd, handled above) and two `config` keys — `gtk-single-instance`
and `gtk-tabs-location` — that Ghostty silently ignores outside its GTK/Linux
build, so the same `config` file works unmodified on macOS.

On macOS, Ghostty prefers `~/Library/Application Support/com.mitchellh.ghostty/config`
over `~/.config/ghostty/config` *if* that folder already has files in it — e.g.
from using the in-app Settings menu before running this installer. On a fresh
Ghostty install there's nothing there yet, so the symlinked XDG path wins with
no extra steps; if you've used the GUI settings first, move anything out of
the Application Support folder before installing.

## The wallpaper system

### Where images come from

`~/Pictures/ghostty` (symlinked to `wallpapers/` in this repo by `install.sh`)
if it contains any images, otherwise `~/Pictures/wallpapers` filtered to dark
ones. The curated folder takes over the moment it holds a file — drop your own
images in there (following the symlink into `wallpapers/`, or replacing it
with a real directory) and nothing else needs to change.

### How it stays readable

This is the part that took several attempts to get right.

Terminal text over a photo is a contrast problem, and the naive fixes all fail:

- **`minimum-contrast`** does not help. Ghostty's docs state it "does not apply
  to Emoji or images" — it compares text against the background *colour*, and
  never measures the background image.
- **Blurring the wallpaper** hurts more than it helps. Blur is what stops a
  wallpaper looking like itself, and the thing actually swallowing text is
  blown-out highlights, not fine detail. Nothing here is blurred by default.
- **A shader that darkens around glyphs** was tried and removed. Detecting text
  by brightness silently does nothing on bright wallpapers (sky pixels read as
  text and get protected); detecting it by local structure fires on every cloud
  edge and produces visible artifacts. Post-processing cannot cleanly separate a
  glyph from photo detail.

What works is unglamorous: **cap the wallpaper's brightness before Ghostty ever
sees it.** Each image is rescaled in linear light so its 99th percentile lands on
a brightness ceiling, then hard-clipped there, and the result is cached as a
"plate". Because no pixel can exceed the cap, worst-case text contrast is known
in advance rather than hoped for:

| `--cap` | worst-case text contrast |
|---:|---|
| 42% | 3.6:1 |
| 35% | 4.7:1 |
| 30% | 5.7:1 |
| 25% | 7.0:1 |
| **20%** | **8.5:1** ← default |
| 15% | 10.1:1 |

The plate is drawn at `background-image-opacity = 1.0` on purpose. Leaning on
opacity to do the dimming means predicting Ghostty's compositing, and measuring
an actual frame against that prediction showed the screen coming out brighter
than the maths said it should. Baking the brightness into the file removes the
guesswork: what is in the plate is what lands on screen.

### When it changes

Two triggers, both applying without a keypress:

- **every new shell** — the zsh hook re-rolls in about 5ms, so each window you
  open gets a different image
- **every 5 minutes** — the rotation timer (systemd on Linux, launchd on
  macOS) re-rolls *and* pushes it to windows that are already open, by sending
  Ghostty `SIGUSR2`, which it's reloaded its config on since 1.2 — the same
  signal on both platforms, no D-Bus or AppleScript involved

## Commands

```sh
ghostty-wallpaper                    re-roll
ghostty-wallpaper --cap 25 --reload  dim the wallpaper further, applied live
ghostty-wallpaper --look bold        preset caps: bold 52% / balanced 42% / subtle 32%
ghostty-wallpaper --set FILE         pin one image
ghostty-wallpaper --off              no background image
ghostty-wallpaper --print            what is showing now
ghostty-wallpaper --reload           also apply to already-open windows
ghostty-wallpaper --prepare          pre-build every plate (rolls stay instant)
ghostty-wallpaper --dark             restrict to dark images only
ghostty-wallpaper --all              ignore the brightness filter
```

`--cap` and `--look` are remembered across rolls and reboots. `--cap` wins until
you set a `--look`, which hands control back to that preset.

Environment overrides: `GHOSTTY_WALLPAPER_DIR`, `GHOSTTY_WALLPAPER_CURATED_DIR`,
`GHOSTTY_WALLPAPER_CAP`, `GHOSTTY_WALLPAPER_BLUR`, `GHOSTTY_WALLPAPER_LOOK`.

## Notes

- Plates are cached in `~/.cache/ghostty-wallpaper/plates`, keyed by image and
  settings, and pruned on `--prepare`. Expect ~1MB per image.
- `background-opacity` is `1.0`. With a background image, window transparency
  stacks the desktop *and* whatever window sits behind Ghostty underneath your
  text. Set it back to `0.92` for the see-through look.
- Stop the rotation with `systemctl --user disable --now ghostty-wallpaper.timer`
  (Linux) or `launchctl bootout gui/$(id -u)/com.luffy.ghostty-wallpaper`
  (macOS). Per-window rolling and manual use are unaffected.

## Environment

- **Linux**: developed on EndeavourOS (Arch), Wayland, zsh + oh-my-zsh +
  starship, Ghostty 1.3.x. Package names in this doc assume Arch; substitute
  your distro's.
- **macOS**: install.sh's launchd branch and the wallpaper script's BSD-tool
  handling are written from Ghostty/macOS documentation and Ghostty's own
  cross-platform SIGUSR2 reload, not verified on real Mac hardware — if
  something doesn't work, it's likely a `stat`/`find` quirk one macOS version
  handles differently.

Both target zsh; other shells only miss the auto-reroll-per-shell hook (the
rest of `install.sh` doesn't care what shell you run).
