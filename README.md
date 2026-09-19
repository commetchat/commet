<p align="center" style="padding-top:20px">
<img src="commet/assets/images/app_icon/app_icon_filled.png" width="128" alt="roscord">

<p align="center">
    <a href="https://github.com/PondLabs/roscord/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/PondLabs/roscord?style=for-the-badge&color=534cdd"></a>
    <a href="https://github.com/PondLabs/roscord/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/PondLabs/roscord?style=for-the-badge&color=534cdd"></a>
    <a href="https://github.com/PondLabs/roscord/issues"><img alt="Issues" src="https://img.shields.io/github/issues/PondLabs/roscord?style=for-the-badge&color=534cdd"></a>
</p>

### Your space to connect

roscord is a client for [Matrix](https://matrix.org) focused on providing a feature rich experience while maintaining a simple interface. The goal is to build a secure, privacy respecting app without compromising on the features you have come to expect from a modern chat client.

# Download

Builds are published on the [releases page](https://github.com/PondLabs/roscord/releases/latest):

| Platform | Asset |
|---|---|
| Windows | `roscord-v<version>-windows-x64-release.zip` |
| Linux | `roscord-v<version>-linux-x64-release.tar.gz` |

Unpack the archive and run `roscord` from inside it. macOS, iOS and Android are not currently built.

# Features

- Supports **Windows** and **Linux**
- End to End Encryption
- Custom Emoji + Stickers
- GIF Search
- Threads
- Encrypted Room Search
- Multiple Accounts
- Spaces
- Emoji verification & cross signing
- Push Notifications
- URL Preview
- Voice rooms with screen sharing, per-stream volume and a soundboard

# Reporting a problem

Open an [issue](https://github.com/PondLabs/roscord/issues/new). The "Report issue" button on the Logs page (Settings → About → Logs, with developer mode on) and on the fatal-error screen both prefill an issue with your build and device details.

# Translation

Strings live in `commet/assets/l10n/intl_*.arb`. `intl_en.arb` is the source of truth; the other locales are edited to match it. See [Development](#development) for how translations are regenerated.

# Development

To build, you require [Flutter](https://flutter.dev), currently v3.41.9

This repo has a monorepo structure, containing two flutter projects: roscord and Tiamat. roscord is the main client, and Tiamat is a sort of wrapper around Material with some extra goodies, which is used to maintain a consistent style across the app. Tiamat may eventually be moved to its own repo, but for now it is maintained here for ease of development.

## Building

### 1. [Install Flutter](https://docs.flutter.dev/get-started/install)

### 2. Install Libraries

roscord requires some additional libraries to be built

```bash
sudo apt-get install -y cmake clang ninja-build rustup libgtk-3-dev libmpv-dev mpv ffmpeg libmimalloc-dev libwebkit2gtk-4.1-dev keybinder-3.0
```

### 3. Fetch Dependencies

You will need to change directory in to the project, then fetch dependencies

```bash
cd commet
flutter pub get
```

### 4. Code Generation

We make use of procedural code generation in some parts of the project. As a rule, generated code will not be checked in to git, and will need to be generated before building.

To run code generation, run the script within the `commet` directory:
`dart run scripts/codegen.dart`

### 5. Building

When building, there are some additional command line arguments that must be used to configure the build.

**Required**

| **Argument** | **Valid Values**                                                          | **Description**                                                                                              |
|--------------|---------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| PLATFORM    | 'desktop', 'mobile', 'linux', 'windows', 'macos', 'android', 'ios', 'web' | Defines which platform to build for                                                                          |
| BUILD_MODE   | 'release', 'debug'                                                        | When building with 'debug' flag, additional debug information will be shown                                  |

**Optional**

| **Argument** | **Valid Values**                                                          | **Description**                                                                                              |
|--------------|---------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| GIT_HASH     | *                                                                         | Supply the current git hash when building to show in info screen                                             |
| VERSION_TAG  | *                                                                         | Supply the current build version, to display app version                                                     |
| BUILD_DETAIL | *                                                                         | Can provide additional detail about the current build, for example if it was being built for Flatpak or Snap |

**Example:**

```bash
cd commet
flutter run --dart-define BUILD_MODE=debug --dart-define PLATFORM=linux
```

# License and provenance

roscord is a hard fork of [Commet](https://github.com/commetchat/commet) by the Commet developers, and is licensed under the GNU Affero General Public License v3, the same license as the original. See [LICENSE](LICENSE) for the full text.

Original work is copyright © the Commet developers and contributors. Copyright for changes made in this fork is held by PondLabs.

The fork keeps Commet's values for anything that would break compatibility with existing installs or with other clients: bundle identifiers, the `chat.commet` URL scheme and the `chat.commet.*` Matrix event types are unchanged on purpose, so a roscord install interoperates with rooms created by Commet. See `third_party/README.md` for the vendored packages this fork modifies in place.
