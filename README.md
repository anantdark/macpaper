# macpaper

Standalone CLI to register a folder of videos and images in macOS **System Settings → Wallpaper** and **Screen Saver**.

Uses only Apple system paths and its own data directory. No other wallpaper apps are required.

## Requirements

- macOS 26 (Tahoe) or later
- [ffmpeg](https://ffmpeg.org/) on `PATH` (`brew install ffmpeg`) — thumbnails + probe
- Xcode Command Line Tools (compiles `encode_temporal` + image-folder helper on first use)
- At least one built-in Apple aerial downloaded once in System Settings (creates the aerial manifest)

## Install

### Homebrew

One-shot (tap + trust + install):

```bash
curl -fsSL https://raw.githubusercontent.com/anantdark/macpaper/refs/heads/main/scripts/install.sh | bash
```

Or step by step:

```bash
brew tap anantdark/macpaper
brew trust anantdark/macpaper   # Homebrew 6+ third-party tap trust
brew install macpaper
```

```bash
macpaper version
brew uninstall macpaper
brew untap anantdark/macpaper
```

Dependency: `ffmpeg` (installed automatically).

### From this checkout (local tap)

```bash
./scripts/brew-install-local.sh
```

### Manual

```bash
./macpaper help
# optional: ln -s "$(pwd)/macpaper" /usr/local/bin/macpaper
```

## Quick start

```bash
# Interactive guide
./macpaper

# Register a folder
./macpaper register ~/Movies/MyWallpapers --name "My Wallpapers"
```

Then reopen **System Settings → Wallpaper** (and Screen Saver).

- Videos appear under your category name in the aerial collections
- Images appear as a registered wallpaper folder

Mistyped commands get “Did you mean …?” hints. Aliases: `add` / `rm` / `ls` / `reload`.

## Commands

### `register <folder>`

| Option | Meaning |
|--------|---------|
| `--name NAME` | Category name in Wallpaper settings (default: folder name) |
| `--videos-only` | Only register videos as live aerials |
| `--images-only` | Only register the folder for still images |
| `--no-transcode` | Always copy/link as-is (screensaver may work; wallpaper freeze usually won’t) |
| `--force-transcode` | Always re-encode with temporal layers (fixes already-registered clips) |
| `--quality {standard,high,max}` | Temporal HEVC bitrate when encoding (default: `high`) |
| `--save-transcoded` | Also copy encodes into `<folder>/transcoded/` |
| `--no-save-transcoded` | Skip the save prompt; don’t write local copies |
| `--no-restart` | Don’t restart WallpaperAgent (batch, then `refresh`) |
| `--dry-run` | Preview without writing |

```bash
./macpaper register ~/Movies/Clips --videos-only --name "Clips"
./macpaper register ~/Pictures/Desktops --images-only
./macpaper register ~/Media/Wallpapers --dry-run
```

**Videos:** `.mp4` `.mov` `.m4v` `.mkv` `.avi` `.webm` `.mts` `.m2ts`  
**Images:** `.jpg` `.jpeg` `.png` `.heic` `.heif` `.tif` `.tiff` `.gif` `.webp` `.bmp`

### `unregister <target>`

Remove a registered **folder**, or a **single video** resolved across all registrations.

`<target>` can be a folder path, asset UUID (from `list`), source path, filename, or unique title fragment.

```bash
./macpaper unregister ~/Movies/MyWallpapers
./macpaper unregister ~/Movies/MyWallpapers --yes
./macpaper unregister B5F705B9-5A54-5FBF-B3A3-54EEB78C473D --yes
./macpaper unregister sunset.mp4 --yes
./macpaper unregister ~/Movies/MyWallpapers --force --yes
```

### `unregister-video [folder] <video>`

Remove **one** video. Folder is optional — without it, macpaper searches every registered folder. Match by asset UUID, path, filename, or unique partial name.

```bash
./macpaper unregister-video B5F705B9-5A54-5FBF-B3A3-54EEB78C473D
./macpaper unregister-video sunset.mp4 --yes
./macpaper unregister-video ~/Movies/MyWallpapers sunset.mp4
./macpaper rm-video ~/Movies/MyWallpapers sun          # unique partial match
```

### `check <path>`

Inspect a video file or folder and report whether each clip is **full aerial-ready**: HEVC in a `.mov`/MP4-family container **with temporal sub-layers** (`tscl`/`tsas`).

```bash
./macpaper check ~/Movies/clip.mp4
./macpaper check ~/Movies/Wallpapers
./macpaper inspect ~/Movies/clip.mp4
```

| Result | Meaning |
|--------|---------|
| **ready** | Screensaver + stop-screensaver → wallpaper freeze |
| **screensaver only** | Plain HEVC — plays as aerial screensaver, but wallpaper ramp fails |
| **needs encode** | Not HEVC / wrong container — will be encoded on register |

`register` runs this check per file. Plain HEVC is re-encoded with VideoToolbox temporal layers so wallpaper freeze works. Skip only when already full-ready (unless `--force-transcode`).

Re-fix clips registered with older macpaper (ffmpeg-only HEVC):

```bash
./macpaper register ~/Movies/MyWallpapers --force-transcode
```
### `list`

Shows only what macpaper manages (not other apps’ custom aerials).

### `refresh`

Restarts `WallpaperAgent` / `cfprefsd` so System Settings reloads.

## How it works

**Videos** — published through macOS’s built-in aerial catalog (`WallpaperAerialsExtension`):

1. Probe each video (same as `check`); skip encode when already full-ready (HEVC + temporal layers)
2. Otherwise encode with VideoToolbox **Main10 + temporal sub-layers** (`BaseLayerFrameRate`) via `helpers/encode_temporal.swift` — ffmpeg cannot emit the `tscl`/`tsas` sample groups WallpaperAgent needs for unlock / stop-screensaver → wallpaper. Slower sources are frame-held up to **240 fps** (Apple aerial cadence) so the unlock ramp has matching timing.
3. Short clips are looped in the encode to ~5 minutes (Apple aerial length) so freeze/looping behaves
4. Store under `~/Library/Application Support/com.apple.wallpaper/aerials/videos/`
5. Write PNG thumbnails under `…/aerials/thumbnails/`
6. Patch `…/aerials/manifest/entries.json` with a macpaper category and `file://` URLs
7. Restart WallpaperAgent

Use `macpaper check <file>` to inspect without registering.

Temporal encoder adapted from [macos-custom-video-wallpaper-fix](https://github.com/AlexisBCD/macos-custom-video-wallpaper-fix) (MIT).
**Images** — register the folder with WallpaperImageExtension (same idea as “Add Folder…” in Settings).

**macpaper-only state:** `~/Library/Application Support/macpaper/`  
Manifest backups: `entries.json.macpaper-bak-*`  
Asset tags use shot IDs prefixed with `MACAPER_` so unregister never touches other apps’ entries.

Optional: with `--save-transcoded` (or answering yes to the prompt), HEVC copies are also written to `<folder>/transcoded/`. That folder is ignored on later scans.

## Tips

- Re-run `register` on the same folder after adding/removing files.
- Prefer calm, looping clips for screensavers.
- If Settings was open during register, quit and reopen it (or run `./macpaper refresh`).

## Uninstall

```bash
./macpaper unregister /path/to/each/registered/folder
rm -rf ~/Library/Application\ Support/macpaper
```

Original media files are never deleted — only copies/links under the aerials directory and Settings registrations.

## License

[GNU General Public License v3.0 or later](LICENSE) (`GPL-3.0-or-later`).
