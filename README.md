<p align="center" style="padding-top:20px">
<img src="https://raw.githubusercontent.com/commetchat/.github/refs/heads/main/assets/banner.png">

<p align="center">
    <a href="https://commet.chat/donate"><img alt="Donate" src="https://img.shields.io/badge/donate-534cdd?style=for-the-badge"></a>
    <a href="https://commet.chat/install"><img alt="Download" src="https://img.shields.io/github/downloads/commetchat/commet/total?style=for-the-badge&color=534cdd"></a>
    <a href="https://matrix.to/#/#commet:matrix.org"><img alt="Matrix" src="https://img.shields.io/matrix/commet%3Amatrix.org?logo=matrix&style=for-the-badge&color=534cdd"></a>
    <a href="https://fosstodon.org/@commetchat"><img alt="Mastodon" src="https://img.shields.io/mastodon/follow/109894490854601533?domain=https%3A%2F%2Ffosstodon.org&style=for-the-badge&logo=mastodon&color=534cdd&logoColor=white"></a>
    <a href="https://bsky.app/profile/commet.chat"><img alt="Bluesky" src="https://img.shields.io/badge/follow-@commet.chat-whitesmoke?style=for-the-badge&logo=bluesky&logoColor=white&color=534cdd"></a>
</p>

### Your space to connect

Commet is a client for [Matrix](https://matrix.org) focused on providing a feature rich experience while maintaining a simple interface. The goal is to build a secure, privacy respecting app without compromising on the features you have come to expect from a modern chat client.


<p align="center" style="padding-top:20px">
<img src="https://raw.githubusercontent.com/commetchat/.github/main/assets/banner_demo.png">

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
  

<details><summary><b>PGP Public Key to verify executables</b></summary>

```
-----BEGIN PGP PUBLIC KEY BLOCK-----

xiYEaVcZBRudW9w7efKKX9fRmwwQ8VSGeBDxPR/L1ZiorA99Ja93y80cQ29tbWV0
IDxjb250YWN0QGNvbW1ldC5jaGF0PsKCBBMbCAAuBQJpVxkFFiEEdJSx+k46noJT
sEiwnYIftF7A4aoCGwECHgEBCwEVARYBJwIZAQAKCRCdgh+0XsDhqiE1sVz/Q146
a/XQm2yeA+QJ4KuD+YY7j1zUl8gNZGJtl4LfvzMlEgrl9Tt8r6FP35mlRhKl+XSG
GwMpXUeHJwxvCM4mBGlXGQUbia8Ea3sb8PNFMjxgTF+gjCOBou6vMn8dCux6QEqs
fSDCwCcEGBsIAJMFAmlXGQUCGwIWIQR0lLH6TjqeglOwSLCdgh+0XsDhqnIgBBkb
CAAdBQJpVxkFFiEExdz0cdzyrZo8ihAhUfYeLD/fY80ACgkQUfYeLD/fY812w6BM
9avvCNSTmyogmsYLBpUb5XxaSe+3J6WhwBHyblaodZ2dlJg+npi1qRnMxvz+jTyQ
ctgmD24jtS2EbXlkCQkACgkQnYIftF7A4aqUviQ+fo2mEwweefVoqGuu2Tx/04B2
RY6FOKYsZL4qnEEO8lW7MoLXhVev8QHxmA6TQae8KZKbh8MXdCHW/cA3ZwjOOARp
VxkFEgorBgEEAZdVAQUBAQdAQatH56zW5TzNugWIsK1UGACqdQ/FCFcG/KT5LDiW
TDwDAQgHwnQEGBsIACAFAmlXGQUCGwwWIQR0lLH6TjqeglOwSLCdgh+0XsDhqgAK
CRCdgh+0XsDhqg1ipzJFtQCftqPRNvYPq96xFw3SAAE3CpAfHi+gwOk3BM7FmMxV
COa2WMfqY9EZxYWMwsbF6wZMdI2w3TLbo68MCc4zBGlXGQUWCSsGAQQB2kcPAQEH
QKcpVnktGVrHWHShUhp2Xb/nX6bQfy57gCe8zQ4Kzp0fwnQEGBsIACAFAmlXGQUC
GyAWIQR0lLH6TjqeglOwSLCdgh+0XsDhqgAKCRCdgh+0XsDhqkolM/gHzXSWM9t5
menzfZtegZnLPZ+n/zufzXdidzGa1K88juIrgoUjGZYJXnPHOJKm8qBXbLBscDkc
SHrEquc3Cw==
=wnah
-----END PGP PUBLIC KEY BLOCK-----
```
</details>

# Translation
Help translate Commet to your language on [Weblate](https://hosted.weblate.org/projects/commetchat/commet/)

<a href="https://hosted.weblate.org/engage/commetchat/">
<img src="https://hosted.weblate.org/widget/commetchat/commet/multi-auto.svg" alt="Translation status" />
</a>

# Development
Commet is built using [Flutter](https://flutter.dev), currently v3.35.4 

This repo currently has a monorepo structure, containing two flutter projects: Commet and Tiamat. Commet is the main client, and Tiamat is a sort of wrapper around Material with some extra goodies, which is used to maintain a consistent style across the app. Tiamat may eventually be moved to its own repo, but for now it is maintained here for ease of development.
## Building

### 1. [Install Flutter](https://docs.flutter.dev/get-started/install)

### 2. Install Libraries
Commet requires some additional libraries to be built 
```bash
sudo apt-get install -y ninja-build libgtk-3-dev libmpv-dev mpv ffmpeg libmimalloc-dev
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
