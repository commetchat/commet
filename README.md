<p align="center" style="padding-top:20px">
<h1 align="center">Commet</h1>
<p align="center">Your space to connect</p>

<p align="center">
    <a href="https://github.com/commetchat/commet/actions/workflows/integration-test.yml">
        <img alt="Integration Test" src="https://github.com/commetchat/commet/actions/workflows/integration-test.yml/badge.svg">
    </a>
    <a href="https://matrix.to/#/#commet:matrix.org">
        <img alt="Matrix" src="https://img.shields.io/matrix/commet%3Amatrix.org?logo=matrix">
    </a>
    <a href="https://fosstodon.org/@commetchat">
        <img alt="Mastodon" src="https://img.shields.io/mastodon/follow/109894490854601533?domain=https%3A%2F%2Ffosstodon.org">
    </a>
    <a href="https://twitter.com/intent/follow?screen_name=commetchat">
        <img alt="Twitter" src="https://img.shields.io/twitter/follow/commetchat?logo=twitter&style=social">
    </a>
</p>

<img src="https://raw.githubusercontent.com/commetchat/.github/main/assets/banner.png">

Commet is a client for [Matrix](https://matrix.org) focused on providing a feature rich experience while maintaining a simple interface. The goal is to build a secure, privacy respecting app without compromising on the features you have come to expect from a modern chat client.

# Features
- Supports **Windows**, **Linux**, and **Android** (MacOS and iOS planned in future)
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
  
# Translation
Help translate Commet to your language on [Weblate](https://hosted.weblate.org/projects/commetchat/commet/)

<a href="https://hosted.weblate.org/engage/commetchat/">
<img src="https://hosted.weblate.org/widget/commetchat/commet/multi-auto.svg" alt="Translation status" />
</a>

# Development
Commet is built using [Flutter](https://flutter.dev), currently v3.22.4 

This repo currently has a monorepo structure, containing two flutter projects: Commet and Tiamat. Commet is the main client, and Tiamat is a sort of wrapper around Material with some extra goodies, which is used to maintain a consistent style across the app. Tiamat may eventually be moved to its own repo, but for now it is maintained here for ease of development.
## Building

### 1. [Install Flutter](https://docs.flutter.dev/get-started/install)

### 2. Install Libraries
Commet requires some additional libraries to be built 
```bash
sudo apt-get install -y ninja-build libgtk-3-dev libolm3 libmpv-dev mpv ffmpeg libmimalloc-dev
```

### 3. Fetch Dependencies
You will need to change directory in to commet, then fetch dependencies
```bash
cd commet
flutter pub get
```

### 4. Code Generation
We make use of procedural code generation in some parts of commet. As a rule, generated code will not be checked in to git, and will need to be generated before building.

To run code generation, run the script within the `commet` directory:
`dart run scripts/codegen.dart`

### 5. Building
When building Commet, there are some additional command line arguments that must be used to configure the build.

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
