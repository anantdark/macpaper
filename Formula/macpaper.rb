class Macpaper < Formula
  desc "Register local videos and images in macOS Wallpaper and Screen Saver"
  homepage "https://github.com/anantdark/macpaper"
  url "https://github.com/anantdark/macpaper/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "af56260827254c95dc770f5b7a3e4f4493e3cf4c47da8645398ee3763836d4d6"
  license "GPL-3.0-or-later"
  version "1.3.1"

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

      Image-folder registration compiles a small Swift helper on first use
      (requires Xcode Command Line Tools: xcode-select --install).
    EOS
  end

  test do
    assert_match "macpaper", shell_output("#{bin}/macpaper version")
    assert_path_exists libexec/"helpers/ImageFolderHelper.swift"
  end
end
