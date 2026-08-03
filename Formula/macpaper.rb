class Macpaper < Formula
  desc "Register local videos and images in macOS Wallpaper and Screen Saver"
  homepage "https://github.com/anantdark/macpaper"
  url "https://github.com/anantdark/macpaper/archive/refs/tags/v1.4.3.tar.gz"
  sha256 "80cc9b11c7bddf70ce86ca4bfd9a8ef8f34d2074f827d64b644b5884e4425503"
  license "GPL-3.0-or-later"
  version "1.4.3"

  depends_on "ffmpeg"
  depends_on :macos

  def install
    libexec.install "macpaper"
    libexec.install "helpers"
    chmod 0755, libexec/"macpaper"
    bin.install_symlink libexec/"macpaper"
  end

  def caveats
    <<~EOS
      macpaper targets macOS 26+ (user aerials catalog under
      ~/Library/Application Support/com.apple.wallpaper/aerials/).

      Before the first register, download at least one built-in aerial in
      System Settings → Wallpaper (or Screen Saver) so entries.json exists.

      First video encode / image-folder register compiles small Swift helpers
      (requires Xcode Command Line Tools: xcode-select --install).

      Videos are encoded with HEVC temporal sub-layers so stop-screensaver
      can freeze that frame as wallpaper. Re-register older clips with:
        macpaper register <folder> --force-transcode
    EOS
  end

  test do
    assert_match "macpaper", shell_output("#{bin}/macpaper version")
    assert_path_exists libexec/"helpers/ImageFolderHelper.swift"
    assert_path_exists libexec/"helpers/encode_temporal.swift"
  end
end
