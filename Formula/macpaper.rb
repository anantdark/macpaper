class Macpaper < Formula
  desc "Register local videos and images in macOS Wallpaper and Screen Saver"
  homepage "https://github.com/anantdark/macpaper"
  url "https://github.com/anantdark/macpaper/archive/refs/tags/v1.4.5.tar.gz"
  sha256 "66f846e46df3f9fc70749b54a04093e763bd1b22b8cbc08ed5dd124a01935a73"
  license "GPL-3.0-or-later"
  version "1.4.5"

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
