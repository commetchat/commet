// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'platform/io.dart' if (dart.library.js_interop) 'platform/web.dart';

// Returns the current platform which works for both web and devices.
PlatformType lkPlatform() => lkPlatformImplementation();

bool lkPlatformIs(PlatformType type) => lkPlatform() == type;

bool lkPlatformIsMobile() => [PlatformType.iOS, PlatformType.android].contains(lkPlatform());

bool lkPlatformIsWebMobile() => lkPlatformIsWebMobileImplementation();

bool lkPlatformIsDesktop() => [
      PlatformType.macOS,
      PlatformType.windows,
      PlatformType.linux,
    ].contains(lkPlatform());

bool lkPlatformSupportsE2EE() => lkE2EESupportedImplementation();

bool lkPlatformIsTest() => lkPlatformIsTestImplementation();

BrowserType lkBrowser() => lkBrowserImplementation();

BrowserVersion lkBrowserVersion() => lkBrowserVersionImplementation();

/// skips stop/replaceTrack for the following platforms and only toggles
/// track.enabled.
bool skipStopForTrackMute() => (lkPlatformIs(PlatformType.web) && [BrowserType.firefox].contains(lkBrowser()));

enum PlatformType { web, windows, linux, macOS, android, fuchsia, iOS }

enum BrowserType {
  chrome,
  firefox,
  safari,
  internetExplorer,
  wkWebView,
  edge,
  unknown,
}

class BrowserVersion {
  const BrowserVersion(this.major, this.minor, this.patch);

  /// The major version number: "1" in "1.2.3".
  final int major;

  /// The minor version number: "2" in "1.2.3".
  final int minor;

  /// The patch version number: "3" in "1.2.3".
  final int patch;
}

bool isChrome129OrLater() {
  if (lkPlatformIs(PlatformType.web) && BrowserType.chrome == lkBrowser()) {
    final version = lkBrowserVersion();
    return version.major > 129 || (version.major == 129 && version.minor >= 0);
  }
  return false;
}
