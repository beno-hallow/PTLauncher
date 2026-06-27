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
  action, a keystroke, or a custom script.
- **Right-click** any button to change its icon, edit its script, set a keyboard
  shortcut, or remove it.
- **Drag** buttons to reorder them.

Your layout lives in `~/Library/Application Support/PTLauncher/config.json` and
is never touched by updates.

## Keyboard shortcuts

Turn them on with **⚙ / Add → Keyboard Shortcuts (1–9 + custom)**. They fire only
while Pro Tools is the active app, and they override Pro Tools' own shortcut for
that key.

- **Number keys:** the first nine buttons map to **⌥1–⌥9** (Option + the number).
  The modifier matters: Pro Tools' transport and nudge fields are invisible to
  macOS accessibility, so a *bare* number couldn't tell "type 3 into the counter"
  apart from "fire button 3." Holding Option avoids that entirely. You can change
  the modifier (or pick None, at your own risk) under **⚙ → Number Key Modifier**.
- **Custom shortcuts:** right-click any button → **Set Shortcut…** and press the
  combo you want (e.g. ⌘⌥H). It overrides the positional number for that button.
  **Clear Shortcut** removes it. Each button shows its shortcut as a small badge.

Setting a shortcut requires granting PT Launcher **Accessibility** permission
(System Settings → Privacy & Security → Accessibility) the first time.

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
