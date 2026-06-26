# PT Launcher — install & update (for the team)

A small floating launcher that sits over the Pro Tools edit window. You build it
once from this repo; after that, updates are a single command.

## Requirements

- macOS 11 or newer
- Apple command-line tools. If you've used Xcode you have them; otherwise run:
  ```bash
  xcode-select --install
  ```

## First-time install

Clone the repo, then run the installer:

```bash
git clone https://github.com/beno-hallow/PTLauncher.git ptlauncher
cd ptlauncher
chmod +x build.sh update.sh
./update.sh
```

`update.sh` compiles the app, installs it to `/Applications`, and launches it.
A small floating "PT Launcher" panel appears whenever Pro Tools is the active app.

> **During the first build** macOS may ask once to allow access to a signing key,
> or to confirm a new certificate — approve it. This is the one-time setup that
> lets your permissions stick across future updates (see below).

### Grant permissions (one time)

The Pro Tools buttons work by sending menu commands to Pro Tools, so macOS asks
for two permissions the first time you click one. Approve both:

- **System Settings → Privacy & Security → Accessibility** → enable **PT Launcher**
- **System Settings → Privacy & Security → Automation** → under PT Launcher,
  enable **Pro Tools** and **System Events**

App-launch buttons need none of this — only the Pro Tools / keystroke actions do.

### Launch at login (optional)

System Settings → General → Login Items → **+** → add PT Launcher.

## Updating

From your repo folder, any time:

```bash
./update.sh
```

That pulls the latest version, rebuilds, replaces the installed app, and
relaunches it. Because the app is always signed with the same local certificate,
**your Accessibility/Automation permissions carry over — no re-granting.**

## Customizing your buttons

You don't need to rebuild for these.

- **Add / ⚙** button (bottom-right of the panel) → add an application, add a Pro
  Tools menu action (e.g. `AudioSuite > Noise Reduction > RX 11 Connect`), edit
  the config file, reload, or quit.
- **Right-click** any button to remove it.

Your personal layout lives in
`~/Library/Application Support/PTLauncher/config.json` and is never overwritten
by updates.

## Troubleshooting

- **Panel doesn't appear:** it only shows while Pro Tools is the frontmost app.
  Switch to Pro Tools. If it's still missing, run `pgrep -lf PTLauncher` to confirm
  it's running.
- **"Apple cannot check it for malware" on first launch:** right-click the app in
  /Applications → **Open** → confirm once.
- **A Pro Tools action does nothing:** the menu path must match your AudioSuite
  menu wording exactly (it varies by RX version). Open the menu in Pro Tools and
  copy the exact names.
- **Build fails:** make sure command-line tools are installed
  (`xcode-select --install`), then run `./build.sh` and read the error.
