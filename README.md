# PT Launcher

A tiny always-on-top floating launcher that sits over your Pro Tools edit window. Compact grid of buttons that can open apps **and** fire custom Pro Tools actions — run an AudioSuite plugin on the selected clip, open RX Connect and send to RX, or send any keystroke.

It's a single Swift file you compile once. No Xcode project, no dependencies.

---

## 1. Build it

You need Apple's command-line tools. If you've ever run Xcode you have them; if not:

```bash
xcode-select --install
```

Then, in this folder:

```bash
chmod +x build.sh
./build.sh
mv PTLauncher.app /Applications/
```

Double-click **PT Launcher** in /Applications to run it. A small floating panel appears. It has no Dock icon — it's a floating utility window that stays above other windows.

To launch it automatically at login: System Settings → General → Login Items → add PT Launcher.

---

## 2. Grant permissions (one time)

The Pro Tools actions work by telling Pro Tools to run a menu command, so macOS will ask for two permissions the first time you fire one. Approve both:

- **System Settings → Privacy & Security → Accessibility** → enable **PT Launcher**
- **System Settings → Privacy & Security → Automation** → under PT Launcher, enable **Pro Tools** and **System Events**

App-launch buttons don't need any of this. Only the Pro Tools / keystroke actions do.

---

## 3. Using it

- **Click a button** to fire it.
- The panel is a *non-activating* window, so clicking it does **not** steal focus from Pro Tools — your clip selection stays put, which is exactly what AudioSuite/RX actions need.
- Drag it anywhere by its title bar; it remembers where you left it.
- **Add / ⚙** button (bottom-right cell) opens the menu: add an app, add a Pro Tools menu action, add a keystroke, edit the config file, reload, or quit.
- **Right-click any button** to remove it.

### Add an app
Add / ⚙ → **Add Application…** → pick any .app. Done.

### Add a Pro Tools action (AudioSuite, RX Connect, etc.)
Add / ⚙ → **Add Pro Tools Menu Action…**. Give it a label, then type the exact menu path as it appears in Pro Tools, separated by ` > `. Examples:

```
AudioSuite > Noise Reduction > RX 11 Connect
AudioSuite > Noise Reduction > RX 11 De-click
AudioSuite > Dynamics > Dyn3 Compressor/Limiter
```

When you click the button, PT Launcher brings Pro Tools forward and clicks straight through that menu — opening the plugin on whatever clip is selected. For **RX Connect**, that opens the RX Connect AudioSuite window; hit Render there to send the audio to RX, edit, and send it back.

> The plugin names and submenu categories must match **exactly** what's in your AudioSuite menu (they vary by RX version and installed plugins). Open the AudioSuite menu in Pro Tools and copy the wording. If you change the target app name in the config, set `targetApp` to match the process name (it's "Pro Tools").

### Add a keystroke
Add / ⚙ → **Add Keystroke Action…**. Useful if you've assigned a Pro Tools key command to something. Enter the key and any modifiers (command, option, control, shift).

---

## 4. The config file

Everything lives in a plain JSON file you can edit by hand (Add / ⚙ → **Edit Config File…**):

```
~/Library/Application Support/PTLauncher/config.json
```

```json
{
  "columns": 3,
  "buttonSize": 78,
  "targetApp": "Pro Tools",
  "buttons": [
    { "title": "RX Connect", "type": "ptMenu",
      "menuPath": ["AudioSuite", "Noise Reduction", "RX 11 Connect"],
      "symbol": "waveform.path.ecg" },

    { "title": "Logic", "type": "app",
      "appPath": "/Applications/Logic Pro.app" },

    { "title": "Bounce", "type": "ptKey",
      "key": "b", "modifiers": ["command"] }
  ]
}
```

- `columns` — buttons per row.
- `buttonSize` — pixel size of each square button.
- `symbol` — optional [SF Symbol](https://developer.apple.com/sf-symbols/) name used as the icon for non-app buttons (e.g. `waveform`, `slider.horizontal.3`, `scissors`).
- After hand-editing, choose **Reload Config**.

---

## Notes & limitations

- Pro Tools has no public scripting API for AudioSuite, so actions are driven through the macOS Accessibility menu, the same path the docs above describe. It's reliable but depends on the menu wording matching exactly.
- If the panel ever hides behind a window, it's at the `.floating` level — fine for the standard Pro Tools edit window. (If you run Pro Tools in true macOS full-screen and it disappears, tell me and I'll bump the window level.)
- This is an unsigned local build, so the first launch may need right-click → **Open** to get past Gatekeeper.
