# Window Templates

A macOS menu bar app for saving and restoring window layouts. Define presets with specific app positions and sizes, then apply them with a single click.

## Features

- Lives in the menu bar — no dock icon
- Create named presets with window positions for any app
- Apply presets instantly from the menu bar
- Visual grid editor for arranging windows
- Automatically launches apps if they aren't running

## Requirements

- macOS 14 (Sonoma) or later
- Accessibility permissions (prompted on first launch)

## Install

### Homebrew

```
brew install alexnaef/tap/window-templates
```

### Manual

Download `WindowTemplates.zip` from the [latest release](https://github.com/alexnaef/claudetism/releases/latest), unzip it, and move `Window Templates.app` to `/Applications`.

## Build from source

```
cd WindowTemplates
swift build -c release
```

Or use the bundled script to produce a signed `.app` bundle:

```
./scripts/build-app.sh
```

The app bundle will be in `build/Window Templates.app`.
