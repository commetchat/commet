# Building the Windows client from WSL

Flutter cannot cross-compile a Windows desktop app from Linux, so the build
runs on the Windows host. Everything below is driven from a WSL shell through
`cmd.exe` / `powershell.exe` interop, but the same commands work in a plain
Windows terminal.

This is what produced the first Windows build of `main` (commit `f9fa7822`)
on 2026-09-14. Paths assume the Windows user `apbia`; adjust as needed.

## One-time setup (already done on this machine)

| Piece | Where | How it was set up |
|-------|-------|-------------------|
| Flutter 3.41.9 (the version CI pins) | `C:\Users\apbia\workspace\flutter-sdk\flutter` | Downloaded `https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.41.9-stable.zip` (1.8 GB) and extracted with Windows `tar.exe`. Not on the system PATH; prepend it per shell. |
| Visual Studio 2022 Community, "Desktop development with C++" workload | default VS location | The workload was missing (only bare MSVC tools were installed, no CMake tools, no Windows SDK). Added with the VS installer, elevated. |
| Rust stable (MSVC target) | `C:\Users\apbia\.cargo\bin` | Was 1.86; several crates in the lockfile refuse anything older than ~1.88. `rustup update stable` fixed it (now 1.98). |
| `nuget.exe` | `C:\Users\apbia\workspace\tools\nuget.exe` | Required by `flutter_inappwebview_windows`' CMake step (it downloads WebView2 and WIL through NuGet). Downloaded from `https://dist.nuget.org/win-x86-commandline/latest/nuget.exe`. |
| Native checkout | `C:\Users\apbia\workspace\roscord` | Cloned from the WSL repo (`git clone /home/lion/workspace/pondlabs/roscord /mnt/c/Users/apbia/workspace/roscord`), then `git remote set-url origin git@github.com:PondLabs/roscord.git`. Build from a native Windows path, not from `\\wsl.localhost\...`: the build is far slower there and plugin symlinks misbehave. |
| Git long paths | global git config | `git config --global core.longpaths true` (CI does the same). |

### Redoing the setup from scratch

From WSL:

```sh
# Flutter SDK
mkdir -p /mnt/c/Users/apbia/workspace/flutter-sdk
curl -L -o /mnt/c/Users/apbia/workspace/flutter_windows_3.41.9-stable.zip \
  https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.41.9-stable.zip
cmd.exe /c "cd /d C:\Users\apbia\workspace\flutter-sdk && tar -xf ..\flutter_windows_3.41.9-stable.zip"

# nuget
mkdir -p /mnt/c/Users/apbia/workspace/tools
curl -L -o /mnt/c/Users/apbia/workspace/tools/nuget.exe \
  https://dist.nuget.org/win-x86-commandline/latest/nuget.exe

# Visual Studio workload (shows a UAC prompt; cmd.exe "start" cannot elevate, PowerShell can)
powershell.exe -NoProfile -Command "Start-Process -FilePath 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe' -ArgumentList 'modify','--installPath','\"C:\Program Files\Microsoft Visual Studio\2022\Community\"','--add','Microsoft.VisualStudio.Workload.NativeDesktop','--includeRecommended','--passive','--norestart' -Verb RunAs -Wait"

# Rust
cmd.exe /c "rustup update stable"

# Checkout
git clone --branch main /home/lion/workspace/pondlabs/roscord /mnt/c/Users/apbia/workspace/roscord
cd /mnt/c/Users/apbia/workspace/roscord && git remote set-url origin git@github.com:PondLabs/roscord.git
```

Check the toolchain once:

```sh
cmd.exe /c "set PATH=C:\Users\apbia\workspace\flutter-sdk\flutter\bin;%PATH% && flutter config --enable-windows-desktop && flutter doctor -v"
```

`flutter doctor` must show Visual Studio without the "missing necessary
components" warning. The Android warnings are irrelevant for this build.

## Building

Mirrors the `build-windows` job in `.github/workflows/build.yml`.

From WSL, one shot:

```sh
cmd.exe /c "set PATH=C:\Users\apbia\workspace\flutter-sdk\flutter\bin;C:\Users\apbia\workspace\tools;C:\Users\apbia\.cargo\bin;%PATH% && cd /d C:\Users\apbia\workspace\roscord\commet && dart run scripts/codegen.dart && flutter build windows --release --dart-define PLATFORM=windows"
```

Or in a Windows terminal:

```bat
set PATH=C:\Users\apbia\workspace\flutter-sdk\flutter\bin;C:\Users\apbia\workspace\tools;%PATH%
cd /d C:\Users\apbia\workspace\roscord\commet
dart run scripts/codegen.dart
flutter build windows --release --dart-define PLATFORM=windows
```

`codegen.dart` runs `flutter pub get`, intl generation and build_runner; it
only needs re-running after pulling changes. The first full build takes
roughly 10 minutes, most of it the Rust library (`wry`, `tao`, `image`)
through cargokit.

Output: `C:\Users\apbia\workspace\roscord\commet\build\windows\x64\runner\Release\`.
`commet.exe` plus all DLLs (about 157 MB) is the whole app; the folder can be
zipped and run elsewhere.

To build a branch other than main:

```sh
cd /mnt/c/Users/apbia/workspace/roscord && git fetch /home/lion/workspace/pondlabs/roscord <branch> && git checkout FETCH_HEAD
```

## Things that went wrong the first time

- **`git clone \\wsl.localhost\...` from cmd.exe fails** ("UNC paths are not
  supported"). Clone from the WSL side into `/mnt/c/...` instead.
- **`start /wait setup.exe ...` from cmd.exe gives "Access is denied."** The
  VS installer needs elevation and cmd cannot request it. Use PowerShell
  `Start-Process -Verb RunAs`.
- **`NUGET-NOTFOUND install Microsoft.Web.WebView2 ...` / exit code 9009**
  during `flutter_inappwebview_windows`. `nuget.exe` was not on PATH. After
  adding it, delete `commet\build\windows` so CMake re-runs its
  `find_program`; the cached NOTFOUND otherwise persists.
- **`rustc 1.86.0 is not supported by the following packages`** from
  cargokit. `rustup update stable`.
- **`flutter doctor` lists "MSVC v142", "C++ CMake tools", "Windows 10 SDK" as
  missing** even with MSVC installed. It is checking for the NativeDesktop
  workload as a whole; adding the workload with `--includeRecommended`
  brings CMake tools and the Windows 11 SDK, which satisfies it.

## Cleanup candidates

`C:\Users\apbia\workspace\flutter_windows_3.41.9-stable.zip` (1.8 GB) is no
longer needed once extracted. The logs `build-win.log`, `codegen-win.log`,
`rustup-update.log`, `flutter-download.log`, `flutter-extract.log` in
`C:\Users\apbia\workspace` are scratch output.
