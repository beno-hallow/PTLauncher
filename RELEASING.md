# Releasing PT Launcher (maintainer guide)

This is for whoever cuts releases. Teammates just download the app (see
INSTALL.md) and get updates automatically via Sparkle.

## One-time setup (per maintainer machine)

1. **Sparkle + signing key**

   ```bash
   ./setup-sparkle.sh
   ```

   Downloads Sparkle into `./Sparkle`, generates your Ed25519 update-signing key
   (private key lives only in your login Keychain), and writes the public key to
   `sparkle_pubkey.txt`. Commit `sparkle_pubkey.txt`.

   > The private key is what proves an update is really from you. Back up your
   > login Keychain; if you lose the key you'll have to ship a new public key in
   > an app update, which existing installs can't auto-accept.

2. **Developer ID certificate** — you need a *Developer ID Application*
   certificate in your Keychain (Xcode → Settings → Accounts → Manage
   Certificates → +). `build.sh` auto-detects it.

3. **Notarization credential** — store an app-specific password once so
   `notarytool` can run unattended:

   ```bash
   xcrun notarytool store-credentials PTLauncher-notary \
     --apple-id "you@appleid.com" --team-id "YOURTEAMID" \
     --password "app-specific-password"
   ```

   Create the app-specific password at https://account.apple.com → Sign-In &
   Security → App-Specific Passwords. (Override the profile name with
   `NOTARY_PROFILE=… ./release.sh` if you used a different one.)

4. **GitHub CLI (optional but recommended)** — `brew install gh && gh auth login`.
   With it, `release.sh` creates the GitHub release and uploads the build for
   you; without it, it pauses and tells you to upload the zip by hand.

## Cutting a release

Bump the version and run one command:

```bash
./release.sh 1.1
```

That will: build + sign with your Developer ID, notarize with Apple, staple the
ticket, zip the app, generate a signed `appcast.xml`, publish the zip to GitHub
Releases as tag `v1.1`, and commit/push the appcast.

Within a day (or immediately if they hit **Check for Updates…**), every existing
install offers the update and installs it on relaunch.

## How the pieces connect

- The app's `Info.plist` points `SUFeedURL` at
  `https://raw.githubusercontent.com/beno-hallow/PTLauncher/main/appcast.xml`.
- `appcast.xml` lists the latest version, its download URL on GitHub Releases,
  and an Ed25519 signature.
- Sparkle (embedded in the app) checks that feed, verifies the signature against
  the public key baked into the app, downloads, and installs.

## Notes

- Versions must increase (`1.0` → `1.1` → `1.2`). `release.sh` writes `VERSION`
  and stamps it into the build.
- The appcast keeps the latest release only; that's all Sparkle needs to offer
  an update.
- If signing/notarization fails the first time, the error from `codesign` /
  `notarytool` is usually specific (e.g. missing entitlement, untrusted cert).
  Fix and re-run `./release.sh` — it's safe to repeat.
