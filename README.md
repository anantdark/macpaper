# macpaper

**Your videos. Apple’s screensaver.**

macpaper is a free terminal tool that turns a folder of videos into native macOS **Screen Savers** (and Wallpaper aerials) — the same system Apple uses for Aerials. No floating windows. No background apps. Just System Settings.

```bash
curl -fsSL https://raw.githubusercontent.com/anantdark/macpaper/refs/heads/main/scripts/install.sh | bash
```

Then:

```bash
macpaper register ~/Movies/MyClips --name "My Clips"
```

Reopen **System Settings → Screen Saver**, pick your category, and you’re done.

Site & guide: **[anantdark.github.io/macpaper](https://anantdark.github.io/macpaper/)**

---

## Why macpaper?

Apple’s Aerial screensavers look incredible — but they’re Apple’s clips, not yours. macpaper plugs **your** videos into that same pipeline so they:

- Appear in **System Settings → Screen Saver** and **Wallpaper**
- Support the native unlock / stop-screensaver freeze (temporal HEVC encode)
- Need **no paid app**, daemon, or overlay window

Think of it as: *drop a folder in, get a real Mac screensaver out.*

## Requirements

- **macOS 26 (Tahoe)** or later
- [Homebrew](https://brew.sh) (for the one-line install)
- [ffmpeg](https://ffmpeg.org/) (installed automatically via Homebrew)
- Xcode Command Line Tools (one-time; macpaper compiles tiny helpers on first use)
- Download **at least one built-in Aerial** once in System Settings (creates Apple’s catalog file)

## Install

**One-shot:**

```bash
curl -fsSL https://raw.githubusercontent.com/anantdark/macpaper/refs/heads/main/scripts/install.sh | bash
```

**Or step by step:**

```bash
brew tap anantdark/macpaper
brew trust anantdark/macpaper   # Homebrew 6+ third-party taps
brew install macpaper
macpaper version
```

## Quick start (beginner)

1. Put some videos in a folder, e.g. `~/Movies/MyClips`
2. Install macpaper (above)
3. Register the folder:

```bash
macpaper register ~/Movies/MyClips --name "My Clips"
```

4. Quit and reopen **System Settings**
5. Go to **Screen Saver** (or **Wallpaper**) → find **My Clips** in the aerial collections
6. Select a clip and enjoy

First run may take a few minutes per video while macpaper encodes them the way macOS expects.

### Useful everyday commands

| What you want | Command |
|---------------|---------|
| See what’s registered | `macpaper list` |
| Add / refresh a folder | `macpaper register ~/Movies/MyClips` |
| Remove one video | `macpaper unregister sunset.mp4` |
| Remove a whole folder | `macpaper unregister ~/Movies/MyClips` |
| Check if a file is ready | `macpaper check ~/Movies/clip.mp4` |
| Reload Settings | `macpaper refresh` |
| Guided menu | `macpaper` (no arguments) |

`unregister` accepts a **folder path**, **asset UUID** (from `list`), **file path**, or **filename**.

## Commands (reference)

### `register <folder>`

| Option | Meaning |
|--------|---------|
| `--name NAME` | Name shown in Settings (default: folder name) |
| `--videos-only` | Only live aerial videos |
| `--images-only` | Only still-image folder registration |
| `--force-transcode` | Re-encode everything (fix older clips / wallpaper freeze) |
| `--no-transcode` | Skip encode (screensaver may work; freeze often won’t) |
| `--quality {standard,high,max}` | Encode bitrate preset (default: `high`) |
| `--save-transcoded` | Also keep copies under `<folder>/transcoded/` |
| `--dry-run` | Preview only |

**Videos:** `.mp4` `.mov` `.m4v` `.mkv` `.avi` `.webm` `.mts` `.m2ts`  
**Images:** `.jpg` `.jpeg` `.png` `.heic` `.heif` `.tif` `.tiff` `.gif` `.webp` `.bmp`

### `unregister` / `unregister-video`

```bash
macpaper unregister ~/Movies/MyClips          # whole folder
macpaper unregister B5F705B9-5A54-…           # one video by id
macpaper unregister sunset.mp4                # one video by name
macpaper unregister-video sunset.mp4 --yes
```

### `check` / `list` / `refresh`

```bash
macpaper check ~/Movies/clip.mp4
macpaper list
macpaper refresh
```

| `check` result | Meaning |
|----------------|---------|
| **ready** | Screensaver + stop → wallpaper freeze |
| **screensaver only** | Plays as screensaver; freeze needs re-encode |
| **needs encode** | Will be encoded on register |

## How it works (short version)

macpaper doesn’t invent a fake screensaver. It publishes your clips into macOS’s **built-in aerial catalog** — the same place Apple’s Aerials live — then restarts WallpaperAgent so Settings notices.

Videos are encoded with **HEVC temporal layers** (required for the native freeze-as-wallpaper ramp). That’s something ordinary ffmpeg alone can’t do; macpaper uses a small VideoToolbox helper for it.

## Tips

- Calm, looping clips feel best as screensavers
- Re-run `register` after you add files to the folder
- If Settings was open during register, quit it or run `macpaper refresh`
- Re-fix old registrations with `macpaper register <folder> --force-transcode`

## Uninstall

```bash
macpaper unregister ~/Movies/MyClips --yes    # each folder you registered
brew uninstall macpaper
brew untap anantdark/macpaper
rm -rf ~/Library/Application\ Support/macpaper
```

Your original videos are never deleted — only system copies and Settings entries.

## License

[GPL-3.0-or-later](LICENSE)

---

Built for people who want **custom Mac screensavers** without buying another wallpaper app.
