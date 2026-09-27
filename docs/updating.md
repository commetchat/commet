# Updating

roscord checks GitHub for a newer release and, on the desktop builds, can
install one over itself. The check is opt-in and the button is always there;
nothing is downloaded or replaced without being asked for.

## Where the versions come from

`ci.yml` cuts a release on every push to `main`: it runs the tests, builds
Windows and Linux through `desktop-build.yml`, works out the next tag, and
`gh release create`s it with both archives attached. They are named
`roscord-<tag>-<platform>-x64-<mode>.<zip|tar.gz>` and each holds a single
top level directory of the same name, which is the bundle.

`release.yml` is the older Commet pipeline and uploads different names
(`roscord-windows.zip`). Nothing runs it today.

The running version is `BuildConfig.VERSION_TAG`, baked in at build time by
`scripts/build_release.dart`. A local build has `development`, which parses
as no version at all, so a development build never reports an update.
`v0.0.0-artifact`, which the release workflow passes for builds that are not
releases, turns the whole thing off (`UpdateChecker.shouldCheckForUpdates`).

## Checking

| Where | What |
|-------|------|
| `lib/utils/update_checker.dart` | The startup check and the "update available" alert. Runs once per launch from the home screen, only when `preferences.checkForUpdates` is true. |
| `lib/utils/updater/update_release.dart` | A release and its assets, and picking the archive for this platform. Release builds only: a debug bundle is not an update. |
| `lib/utils/updater/self_updater.dart` | The stages the button shows, and the platform switch. |
| `lib/utils/updater/self_updater_native.dart` | Desktop: download, verify, unpack, swap. |
| `lib/ui/organisms/update_button.dart` | The button in general settings. |

The request is one unauthenticated GET to
`api.github.com/repos/PondLabs/roscord/releases/latest`, which is rate
limited to 60 an hour per IP. `releases/latest` leaves out prereleases by
design.

The button is always shown, whatever the preference says: that preference
only governs the check that runs by itself at startup, and somebody who
turned it off should still be able to ask.

## Installing over the running build

Only where the build was unpacked from the archive above. A flatpak (`/app`),
a .deb or a distro package (`/usr`), a snap and a nix store path all belong to
something else and are refused (`isSelfInstallable`); so are Android and the
web. There, the button opens the release page, which is all the app ever did.

1. **Download** the archive for this platform to `.roscord-update/<tag>/`
   beside the install, or the temp directory when that is not writable.
   Beside it means putting it in place is a rename rather than a copy
   between filesystems. Where the install is comes from `updateTargetFor`
   (below).
2. **Verify** it against the `sha256` GitHub reports for the asset. An asset
   without one is not installed: there would be no way to know what arrived,
   and this unpacks over the app.
3. **Unpack** with the system's `tar`, falling back to the `archive` package.
   Windows has shipped bsdtar, which reads zip too, since Windows 10 1803.
   The Dart unpacker takes about three minutes over a 57 MB release where tar
   takes under a second, and it drops the executable bit, which would leave a
   build that cannot start.
4. **Swap**, when the user says to. A running program cannot replace its own
   directory on Windows, so a script is written next to the staged build and
   started detached: it waits for the process to go, moves the install aside,
   moves the new one in, starts it, and clears up all of `.roscord-update/`.
   If the new one will not go in, the old one is moved back — a failure
   leaves the build that was already working, and on Windows starts it
   again and keeps `install-<stamp>.log` in `.roscord-update/`.

On Windows:

- The script is started in the temp directory. It used to inherit the app's
  working directory, which is the install when Explorer starts it, and
  Windows will not rename a directory a process is working in: no swap ever
  happened, and people ran the staged build from `.roscord-update/` instead.
- Moves are `[System.IO.Directory]::Move`, retried for 30 seconds while the
  install is busy (the CEF helpers closing, a virus scanner). `Move-Item`
  moves a directory with a busy file in it one file at a time and leaves
  half an install.

### Where the install is

`updateTargetFor` works it out from the running executable:

- **Its own directory**, normally.
- **Run from inside `.roscord-update/`** (a swap that never happened, the
  staged build started by hand, maybe more than once, each staging the next
  inside itself): the build left beside the outermost `.roscord-update/` is
  replaced, and the whole nest is cleared with the swap.
- **Run from a zip opened in Explorer**, which unpacks it under the temp
  directory: the update goes to `%LOCALAPPDATA%\Programs\roscord`, with a
  Start menu shortcut, since the next click on the zip would start the old
  build again. The button says so before the restart.

The swap scripts are `windowsSwapScript` and `linuxSwapScript`, kept as
plain functions so `unit_test/updater/self_updater_test.dart` (Linux) and
`windows_swap_test.dart` (Windows, started the way the app starts it, from
inside the install) can run them for real against directories that are not
an install.

## Known gaps

- Nothing is signed, so Windows SmartScreen may have an opinion about the
  build that is started after a swap.
- An install under `Program Files` needs elevation to swap. This does not ask
  for it: the write probe fails, so the download lands in the temp directory
  and the move across filesystems is a copy.
- macOS has no self-update path, in line with there being no macOS release.
- Every push to `main` publishes a release, so "update available" is a
  frequent thing to see.
