# macpaper

Standalone CLI to register a folder of videos and images in macOS **System Settings → Wallpaper** and **Screen Saver**.

Uses only Apple system paths and its own data directory. No other wallpaper apps are required.

## Requirements

- macOS 26 (Tahoe) or later
- [ffmpeg](https://ffmpeg.org/) on `PATH` (`brew install ffmpeg`)
- Xcode Command Line Tools (one-time compile of the image-folder helper)
- At least one built-in Apple aerial downloaded once in System Settings (creates the aerial manifest)

## Install

### Homebrew

One-shot (tap + trust + install):

```bash
curl -fsSL https://raw.githubusercontent.com/anantdark/macpaper/main/scripts/install.sh | bash
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
| `--no-transcode` | Always copy/link as-is (even if check says not ready) |
| `--force-transcode` | Always re-encode, even if already aerial-ready |
| `--quality {standard,high,max}` | Encode quality when transcoding (default: `high`) |
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

### `unregister <folder>`

Remove an entire previously registered folder (all videos + image-folder entry). Asks for confirmation unless `--yes`.

```bash
./macpaper unregister ~/Movies/MyWallpapers
./macpaper unregister ~/Movies/MyWallpapers --yes
./macpaper unregister ~/Movies/MyWallpapers --force --yes
```

### `unregister-video <folder> <video>`

Remove **one** source video from Wallpaper / Screen Saver. The name may be a unique partial match (e.g. `sun` → `sunset.mp4`). Asks for confirmation unless `--yes`.

Deletes only that aerial listing, its system encode/thumbnail, and its local `transcoded/` copy if present. Other videos stay.

```bash
./macpaper unregister-video ~/Movies/MyWallpapers sunset.mp4
./macpaper rm-video ~/Movies/MyWallpapers sun          # unique partial match
./macpaper unregister-video ~/Movies/MyWallpapers sun --yes
```

### `check <path>`

Inspect a video file or folder and report whether each clip is **aerial-ready without transcoding** (HEVC in a `.mov`/MP4-family container).

```bash
./macpaper check ~/Movies/clip.mp4
./macpaper check ~/Movies/Wallpapers
./macpaper inspect ~/Movies/clip.mp4
```

If it says **ready**, register with `--no-transcode` to avoid re-encoding. If it **needs transcode**, use `--quality high` (default) or `--quality max` for less loss.

`register` runs this same check automatically per file and skips encoding when ready (unless `--force-transcode`).

### `list`

Shows only what macpaper manages (not other apps’ custom aerials).

### `refresh`

Restarts `WallpaperAgent` / `cfprefsd` so System Settings reloads.

## How it works

**Videos** — published through macOS’s built-in aerial catalog (`WallpaperAerialsExtension`):

1. Probe each video (same as `check`); skip encode when already aerial-ready
2. Otherwise transcode to HEVC `.mov` (`hvc1`) with `--quality standard|high|max`
3. Store under `~/Library/Application Support/com.apple.wallpaper/aerials/videos/`
4. Write PNG thumbnails under `…/aerials/thumbnails/`
5. Patch `…/aerials/manifest/entries.json` with a macpaper category and `file://` URLs
6. Restart WallpaperAgent

Use `macpaper check <file>` to inspect without registering.

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
