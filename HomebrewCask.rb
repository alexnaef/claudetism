# Reference cask formula for alexnaef/homebrew-tap
# Copy this file to Casks/window-templates.rb in the homebrew-tap repo
# and update the version and sha256 after each release.

cask "window-templates" do
  version "0.1.0"
  sha256 "REPLACE_WITH_SHA256_FROM_RELEASE"

  url "https://github.com/alexnaef/claudetism/releases/download/v#{version}/WindowTemplates.zip"
  name "Window Templates"
  desc "Menu bar app for saving and restoring window layouts on macOS"
  homepage "https://github.com/alexnaef/claudetism"

  depends_on macos: ">= :sonoma"

  app "Window Templates.app"

  zap trash: [
    "~/Library/Application Support/WindowTemplates",
  ]
end
