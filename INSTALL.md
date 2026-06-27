# PT Launcher — install & update (for the team)

A small floating launcher that sits over the Pro Tools edit window. Download it
once; after that it updates itself automatically.

## Install

1. Go to the latest release:
   **https://github.com/beno-hallow/PTLauncher/releases/latest**
2. Download **`PTLauncher-<version>.zip`** and unzip it (double-click).
3. Drag **PT Launcher** into your **Applications** folder.
4. Open it. A small floating "PT Launcher" panel appears whenever Pro Tools is
   the active app, and a waveform icon appears in your menu bar.

The app is signed and notarized by Apple, so it opens normally with no security
warnings.

To launch it automatically at login: System Settings → General → Login Items →
**+** → add PT Launcher.

## Grant permissions (one time)

The Pro Tools buttons work by sending commands to Pro Tools, so macOS asks for
two permissions the first time you use one. Approve both:

- **System Settings → Privacy & Security → Accessibility** → enable **PT Launcher**
- **System Settings → Privacy & Security → Automation** → under PT Launcher,
  enable **Pro Tools** and **System Events**

App-launch buttons need none of this — only the Pro Tools / script actions do.

## Updates — automatic

PT Launcher checks for new versions on its own and will prompt you to install
when one is available; it installs on the next relaunch. You can also trigger a
check any time: panel **⚙ / Add** button → **Check for Updates…**.

Your buttons and layout are kept across updates.

## Customizing your buttons

- The **⚙ / Add** button (end of the strip) → add an application, a Pro Tools
  action, a keystroke, or a custom script; toggle number hotkeys.
- **Right-click** any button to change its icon, edit its script, or remove it.
- **Drag** buttons to reorder them.

Your layout lives in `~/Library/Application Support/PTLauncher/config.json` and
is never touched by updates.

## Troubleshooting

- **Panel doesn't appear:** it only shows while Pro Tools is the frontmost app —
  switch to Pro Tools, or click the menu-bar waveform icon to toggle it.
- **A Pro Tools action does nothing:** its menu path / script must match your
  AudioSuite menu wording exactly (it varies by RX version). Right-click the
  button → Edit Script to check.
- **Stuck on an old version:** use **Check for Updates…** from the menu; if it
  still won't update, re-download from the Releases page above.

---

### For developers (build from source)

You don't need this to use the app. To hack on it:

```bash
git clone https://github.com/beno-hallow/PTLauncher.git
cd PTLauncher
./setup-sparkle.sh        # one time: fetch Sparkle + generate signing key
./build.sh                # builds & signs PTLauncher.app
open PTLauncher.app
```

Cutting and publishing releases is documented in **RELEASING.md**.
