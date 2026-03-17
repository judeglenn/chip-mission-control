# Chip Mission Control

A native macOS menubar app that serves as a personal AI assistant dashboard for an OpenClaw gateway running on localhost.

## Features

- **Gateway Status** — Live health check of `http://127.0.0.1:62314/` with green/red icon indicator, PID display, and one-click restart
- **Cron Jobs** — Lists jobs from `openclaw cron list --json` with name and next run time
- **Quick Actions** — Open workspace, view logs, launch gateway dashboard in browser
- **System Info** — OpenClaw version, auto-refreshes every 30 seconds
- **No dock icon** — Pure menubar app (`LSUIElement = true`)

## Requirements

- macOS 13.0+
- Xcode 15+
- `openclaw` CLI installed and available in `/usr/local/bin` or `/opt/homebrew/bin`

## Build & Run

### Option 1: Open in Xcode

```bash
open ChipMissionControl.xcodeproj
```

Then press **⌘R** to build and run.

### Option 2: Build from command line

```bash
xcodebuild -project ChipMissionControl.xcodeproj \
           -scheme ChipMissionControl \
           -configuration Release \
           -derivedDataPath build \
           build
```

The app will be at:
```
build/Build/Products/Release/ChipMissionControl.app
```

Run it:
```bash
open build/Build/Products/Release/ChipMissionControl.app
```

### Option 3: Install to Applications

```bash
xcodebuild -project ChipMissionControl.xcodeproj \
           -scheme ChipMissionControl \
           -configuration Release \
           -derivedDataPath build \
           build

cp -R build/Build/Products/Release/ChipMissionControl.app /Applications/
open /Applications/ChipMissionControl.app
```

## Launch at Login

After installing to `/Applications/`, add it to Login Items:
- **System Settings → General → Login Items** → click `+` → select `ChipMissionControl.app`

## Project Structure

```
ChipMissionControl.xcodeproj/     — Xcode project
ChipMissionControl/
  ChipMissionControlApp.swift     — App entry point (@main)
  AppDelegate.swift               — NSStatusItem setup, popover management
  ContentView.swift               — All UI panels (SwiftUI)
  GatewayMonitor.swift            — ObservableObject: health polling, cron jobs, version
  ShellRunner.swift               — Process wrapper for running shell commands
  Info.plist                      — LSUIElement=true (no dock icon)
  Assets.xcassets/                — Asset catalog
```

## Gateway URL

Hardcoded to `http://127.0.0.1:62314/`. Edit `GatewayMonitor.swift` to change it.
