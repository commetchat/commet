# CHANGELOG

## 2.7.0

* Added: Add setVideoDimensions for remote track publications
* Added: Add audio renderer API for receiving raw audio frames
* Changed: Bump flutter-webrtc to 1.4.0 and upgrade to libwebrtc m144
* Fixed: Add signal RTT tracking via pingReq/pongResp
* Fixed: Add jitter to reconnect retry delays
* Fixed: Fix missing params in CameraCaptureOptions.copyWith
* Fixed: Fix missing RoomReconnectedEvent and incorrect SyncState timing during signal-only reconnection
* Fixed: Fix VP9/SVC dynacast layer handling
* Fixed: Stop processor on track end
* Fixed: Include last server offer in SyncState during reconnection

## 2.6.5

* Added: Send reconnect reason to server during WebSocket reconnection
* Fixed: setProcessor() now uses VideoProcessorOptions for video tracks instead of AudioProcessorOptions
* Fixed: Fix wildcard variable lint warnings to improve pub.dev score
* Fixed: Preserve Bluetooth and AirPlay options when forcing speaker output on iOS
* Fixed: MissingPluginException when stopping audio visualizer on Android/iOS
* Fixed: Fix microphone stopping after pre-connect audio completes
* Fixed: Duplicate tracks published when setCameraEnabled called rapidly

## 2.6.4

* Added: Add web support for pre-connect audio buffer
* Fixed: Remove duplicate sendLeave
* Fixed: Fix setVideoInputDevice not switching camera
* Fixed: Web pre-connect audio buffer using wrong sample rate
* Fixed: Fix iOS audio renderer resource leak and remove Android 32-bit dead code
* Fixed: Fix web audio capture not starting on Safari due to suspended AudioContext
* Performance: Send raw PCM bytes in audio renderer instead of boxed int arrays

## 2.6.3

* Fixed: Fix publisher connection causing redundant renegotiations on lower-end devices
* Fixed: Use explicit show clauses for foundation imports
* Fixed: Fix concurrent modification on collection iteration during async operations
* Fixed: Fix crash when writing to closed data stream controllers
* Fixed: Fix region URL provider cache using wrong time unit and wrong field check for regions in leave event
* Chore: Update protobuf to v1.44.0

## 2.6.2

* Added: Bitrate priority control APIs
* Fixed: Windows: stop camera after unpublishing video track
* Fixed: Keep mute state in sync with server
* Fixed: Fix example prejoin device dropdown handling
* Chore: Mark LocalVideoTrack constructor as internal for consistency with LocalAudioTrack
* Chore: Update protobuf dependency to v6.0.0
* Chore: Skip iOS platform download in CI

## 2.6.1

* Fixed: Enable E2EE for VP9 codec
* Fixed: Correct spelling in E2EE log and error messages
* Fixed: Ensure all dispose functions are executed even if one throws
* Fixed: Fix microphone label typo in example app prejoin audio settings
* Docs: Fix typos and inconsistencies in README and CHANGELOG

## 2.6.0

* Session API
* Allow customizing screen share dialog labels for localization

## 2.5.4

* Added pre-connect audio buffering
* Added token source API with caching and endpoint helpers
* Enabled software AEC/NS/AGC for Linux
* Added event logging with public/internal tagging
* Migrated manual JSON serialization to json_serializable code generation
* Re-enabled Flutter lint warnings and fixed existing issues
* Improved reliable data channel buffering, sequencing, and added integration tests
* Fixed race condition with pending tracks

## 2.5.3

* Feat: Data Packet Cryptor (#873)
* Feat: Add E2EE support for H265 (#864)
* Fix: fix async call for update participant info (#897)
* Move the accessToken to header (#891)
* Bumpup and clamp connection timeout, fix the comment (#893)
* Fix events emit order (#902)

## 2.5.2

* Fix missing properties for TextStreamInfo (#881)
* Enum for TextStreamOperationType (#882)
* Fix stream progress (#884)

## 2.5.1

* Fix Publication's track property initialization (#867)
* Fix Missing attributes in data stream (#865)
* Fix Internal WebRTC pod version conflict (#876)

## 2.5.0+hotfix.3

* fix: Fix @internal conflicting imports from package meta or flutter/foundation.

## 2.5.0+hotfix.2

* hotfix: bump libwebrtc to m137.7151.03 to support H.265 (#837)
* feat: Expose ParticipantState (#848)
* chore: Update protobuf to v1.39.2 (#847)

## 2.5.0+hotfix.1

* fix: Switch to livekit fork of noise for 16KB page support (#839)
* hotfix: bump libwebrtc to m137.7151.01 for android (#837)
* fix: tighten VideoTrackRenderer Widget (#695)

## 2.5.0

* Bump flutter-webrtc to 1.0.0.
* Upgrade libwebrtc to m137.7151
* fix: E2EE bug for Chrome. (#832)
* fix(web, firefox): backup old values before overwriting them (#819)
* fix: memory leak visualizer stop android (#831)
* fix: ensure engine always has correct device id if switching camera fails (#820)
* fix: Always emit RoomDisconnectedEvent when the reason is clientInitiated. (#821)
* fix: sif frame enqueuing with e2ee (#822)
* fix: update camera `deviceId` when track is null (#814)
* feat: Audio Visualizer for Windows/Linux. (#739)

## 2.4.9

* Added: Attribute typings for agent and transcription (#811)
* Changed: Enum for VideoView.fit (#806)
* Chore: Update protobuf protocol to v1.39.2 (#812)

## 2.4.8

* fix: fix room.disconnect when pending reconnect. (#802)
* fix: fix bitrate display for remote video track. (#801)
* feat: add a flag to skip auto native audio config (#797)
* fix: sif detection for e2ee (#788)
* chore: Update protobuf dep (#790)

## 2.4.7

* fix: interop for encode and decode function in e2ee cryptor (#785)
* chore: Unorder the lossy data channel (#783)
* chore: bump flutter-webrtc to 0.14.1.
* fix: mitigate reconnect loop (#780)

## 2.4.6

* feat: Add smoothTransition option for AudioVisualizer. (#773)
* fix: Fix deadlock when creating a frame cryptor on iOS/macOS.
* fix: add task runner for linux to fix crashes.

## 2.4.5

* feat: noise filter for flutter web. (#762)

## 2.4.4

* feat: data stream
* fix: calling setSourceEnabled should not affect the current output settings (#754)
* fix: Calling connect on a disconnected room instance should reset _isClosed. (#752)
* fix: Fix for Chrome getUserMedia "ideal" Constraint Change.
* fix: fix duplicate fmtp for vp9 on some old Android devices. (#758)

## 2.4.3

* feat: Automatically configure audio mode for Android. (#746)

## 2.4.2+hotfix.2

* fix: Fix creation timing for local participant. (#749)
* fix: Filter out non-video codecs for fast video track publication. (#747)

## 2.4.2+hotfix.1

* fix: fixed bug for fast track publish.

## 2.4.2

* fix: Fixed the echo issue on some specific models of Android devices.
* chore: Bbmp version for flutter-webrtc.
* fix: Improve browser version detection, fix issue #730 (#738)
* feat: Fast track publication. (#720)
* chore: Remove `bypassVoiceProcessing = true` settings for connect page. (#693)
* fix: [bug] Crash when join room on Windows.
* fix: Disable selectAudioInput for mobile platforms.

## 2.4.1

* feat: VideoRenderer support cache renderer. (#723)
* feat: Visualizer for web. (#718)
* fix: Fix bar Visualizer overflow for Android. (#717)
* fix: disconnect reason inconsistent. (#715)
* fix: remove stats video data print from logs (#716)

## 2.4.0

* feat: RPC. (#682)
* fix: Properly handle broadcast capture state (#705)

## 2.3.6

* Emit a final empty AudioVisualizerEvent after track stops (#701)
* fix: Improve speaker switching logic for iOS. (#692)

## 2.3.5

* feat: add TrackProcessor support. (#657)
* fix: bug for mute/unmute and speaker switch. (#684)

## 2.3.4+hotfix.2

* fix: side effects for stop remote track.

## 2.3.4+hotfix.1

* fix: bug for speakerPhone switch. (#672)

## 2.3.4

* fix bypass voice processing not work. (#668)
* fix track.stop for remote track. (#669)
* fix Visualizer block UI. (#667)

## 2.3.3

* Support FocusMode/ExposureMode for camera capture options. (#658)
* Fix Swift compilation errors (#662)
* Improve reconnect logic. (#654)
* Fixed bug for Screen Share on iOS/Android.

## 2.3.2

* Add support for audio visualizer.

## 2.3.1+hotfix.1

* Fix version mismatch for CocoaPods (#648)
* Android AGP upgrade (#649)

## 2.3.0

* fix: Fixed speaker cannot be switched on iOS. (#617)
* feat: Increase default audio bitrate. (#616)

## 2.2.8

* Fix TrackStreamStateUpdatedEvent not emitted. (#612)

## 2.2.7

* feat: support bypass voice processing. (#595)
* fix: Dispose LocalParticipant when room.disconnect. (#609)
* Fix spelling error in method name: _checkPremissions to_checkPermissions (#605)
* fix: fix speaker switching behavior for android. (#604)
* fix: Optimize stats display (#602)
* fix: Handle disconnect reasons correctly. (#594)

## 2.2.6

* fix: android build failure. (#587)
* Update README.md for Android Screenshare (#583)

## 2.2.5

* upgrade flutter-webrtc to 0.11.7
* upgrade web to 1.0.0
* feat: Add timestamps to TranscriptionSegment. (#577)
* feat: Prepare connection/region pinning. (#574)

## 2.2.4

* fix bug for PlatformView on iOS (#570)
* Deprecated `connectOptions` in `Room` constructor.
* Deprecated `roomOptions` int `room.connect`.
* Added `screenShareEncoding` for `VideoPublishOptions`.
* Change `CameraCaptureOptions.params.encoding` to optional.
   It is recommended to use `VideoPublishOptions.videoEncoding/screenShareEncoding`
   to control the video sending bitrate.

## 2.2.3

* add PlatformView for iOS (#509)
* update lints to 4.0.0. (#563)

## 2.2.2

* feat: expose DegradationPreference for publish options. (#556)
* fix room.disconnect issue. (#559)
* fix: use getSettings() to get actual dimensions for mobile (#560)
* Add support for participant attributes (#558)

## 2.2.1

* fix: fix crash for windows
* feat: bump version for flutter-webrtc.
* fix: ratchet on a single frame until ratchetWindowSize (#544)
* fix: fix mediaStreamTrack.getSettings() on Flutter Web.

## 2.2.0

* feat: add Transcription Event. (#531)
* feat: Expose Participant.Kind. (#532)
* fix: ignore unable to parse frames completely (#530)

## 2.1.6

* Framecryptor decrypting fixes (#520)
* feat: add voiceIsolation support (#523)
* fix: audio session control for ios.

## 2.1.5

fix: audio devcie ids consistency (#513)
feat: provide option to skip stop/restartTrack for mute/unmute (#516)

## 2.1.4

* bump version of flutter-webrtc with privacy manifest files

## 2.1.3

* upgrade to connectivity plus 6.x.
* bump dart_webrtc to 1.4.3.

## 2.1.2

* fix: Expose keyRingSize/discardFrameWhenCryptorNotReady parameters for KeyProvider

## 2.1.1

* update to package:web (#484)
* feat: add keyRingSize/discardFrameWhenCryptorNotReady to KeyProviderOptions. (#493)

## 2.1.0

* Fix: bug for sync state (#491)

## 2.0.3

* Read capabilities from RtcRTPReceiver instead of from sender. (#488)
* Update screenshare logic for svc publishing (#487)
* Prevent screen-sharing on flutter web mobile. (#486)
* feat: add setKey variant, setRawKey (#482)

## 2.0.2

* Add Android 14 media projection perm to docs (#470)
* fix package of MainActivity.kt (#472)
* Fix: Remember last settings for republish all tracks (full-reconnect). (#475)
* Fix: Add screenshareAudioEnabled method (#473)
* Fix: use latest key index for new rtp nodes (#476)

## 2.0.1

* bug fix for sync streams.

## 2.0.0

## Breaking Changes

There are several breaking changes between v1 and v2. Please consult our [migration guide](https://docs.livekit.io/guides/migrate-from-v1/) when upgrading to v2.

* `Room.participants` was renamed to `Room.remoteParticipants`
* `Room.{audio/video}Tracks` was renamed to `Room.{audio/video}TrackPublications`
* `LocalParticipant.publishData` now uses participant identity as destinations instead of participant sids.
* `Room.sid` now changed to `await room.getSid();`.
* Removed `VideoQuality.OFF` from `VideoQuality` enum.

## Removal of previously deprecated APIs

* `LiveKitClient.connect` - Please use `var room = Room(...)` and `room.connect` instead.
* `track in TrackMutedEvent/TrackUnmutedEvent` - Use `publication` instead
* `TrackStreamStateUpdatedEvent.trackPublication` - Use `TrackStreamStateUpdatedEvent.publication` instead
* `RemotePublication.videoQuality` - Use `RemotePublication.setVideoQuality(quality)` instead
* `RemotePublication.subscribed` - Use `RemotePublication.subscribe()` or `unsubscribe()` instead
* `RemotePublication.enabled` - Use `RemotePublication.enable()` or `disable()` instead
* `Participant.unpublishTrack` - Use `Participant.removePublishedTrack` instead
* Removed `AudioPublishOptions.stopMicTrackOnMute`

## Other changes

* Do not emit Reconnecting event during connection resume. (#459)
* Cleanup when remove remote participants. (#460)
* Support change key index for encryptors. (#457)
* Bug fixes for e2ee (Web/Firefox). (#453)
* Add lost quality (Protocol v11). (#443)
* [E2EE] Add key handler for web worker. (#449)
* E2EE improvement. (#461)

## 1.5.6

* Set different rendering methods for web and native.
* Improve reconnection events, add RoomAttemptReconnectEvent.
* upgrade protocol.

## 1.5.5

* Improve reconnect logic for websocket (#406)
* Fix: Prevent ReplayKitChannel related code from being executed on non-iOS platforms. (#432)

## 1.5.4

* Add AudioSourceStats.
* Fix: invalid muted state for local publication.
* Add MediaConnectException.
* Fix preview bug for desktop screen share.
* Fix errors caused by window close handler for web.
* Add topic for search optimization in pub.dev.
* Fix safari screen sharing failure.
* Fix e2ee worker compile for flutter web.
* Fix video renderer issue.
* Fix: video renderer dispose issue and correctly handle metadataMuted for TrackPublication.
* Fix getStats for remote track.
* Fix set setScreenShareEnabled when detect replaykit state changed.
* Improve room/participants metadata update.
* Simplify backupCodec setting.

## 1.5.3

* Handling of incompatible published codecs.
* Fix/unpublish screen audio track when stop screen share.
* Upgrade connectivity_plus version.
* Fix: low-resolution screen sharing for safari 17.
* Update build.gradle for gradle 8.0.0 namespace.
* Fix captureScreenAudio conditional.
* Fix iOSBroadcastExtension always false after copyWith invoked.
* Fix: VP9 svc screenshare.
* Fix iOS example compilation after upgrading to XCode 15.
* Fix: Crop video output size to target settings (iOS/macOS).
* Fix: Fix bluetooth sco not stopping after room disconnect (Android).

## 1.5.2

* Non-functional update, forcing the versions in
  `'ios/livekit_client.podspec', 'macos/livekit_client.podspec', 'lib/src/livekit.dart'`
  consistent with pubspec.yaml

## 1.5.1

* Fixed Renderer bug for Windows.
* E2EE Improvements.
* Fixed error when sending events on non-platform thread [iOS/macOS].

## 1.5.0

* Update default bitrates according to VMAF guide
* Support multi-codec simulcast.
* Support SVC publishing with AV1/VP9.
* More robustness for E2EE.
* Configurable Audio Modes for Android.

## 1.4.3

* Fix: remove js_bindings and use the built-in AudioContext for js interop to support flutter 3.13.0.

## 1.4.2

* Fix: fix the speakerPhone switch issue for Android.
* Fix: fix iOS cannot publish the audio track correctly.
* Fix: fix crash when re-publish video track on Windows/Linux.
* Fix: set preferCurrentTab to false by default

## 1.4.1

* Fix: fix Android earpiece not being replaced after wired headset is disconnected.
* Fix: SpeakerPhone switch for Android.
* Feat: expose Android audio modes.
* Fix: Correctly save speakerOn state and restore in AudioManagement.

## 1.4.0

* Upgrade flutter-webrtc to 0.9.36 (libwebrtc m114).
* Fix: Skip decryption when ratchet exceeded.
* Fix SpeakerPhone switch for mobile.
* Fix: Fix data channel cannot be opened due to events loss.

## 1.3.5

* Fix: Fix ScreenShareCaptureOptions not passed correctly.
* Fix: facingMode for mobile web.
* Fix: add name to AudioPublishOptions.
* Fix: track not stop stats monitor correctly.
* Feat: add preferCurrentTab support for flutter web.
* Fix incorrect 4:3 preset bitrates
* Fix: fix wrong override when options is not null when LocalTrack.create.

## 1.3.4

* Fix: Frame drops for Android.

## 1.3.3

* Fix: issue for get user audio on Android.

## 1.3.2

* Fix: Improve iOS/macOS H264 encoder.
* Fix: Default capture/publish options for fast connect.

## 1.3.1

* Feat: add linux support.
* Fix: audio play bug for ios safari.
* Fix: fix bluetooth device enumerate on android.
* Fix: Do not operate on inactive tracks.
* Fix: use the correct transceiver id.
* Fix: Support restart camera for windows/linux.
* Fix: Move the call of capturer.stopCapture() outside the main thread
       to avoid blocking of flutter method call.
* Fix: Handle exceptions for framerate settings for darwin.

## 1.3.0

* Fix resolution/framerate/bitrate issue for publishVideoTrack.
* End-to-end encryption support.

## 1.2.2

* Feat: Support setVideoFPS for subscribe.
* Feat: topic for data-channel.
* Feat: support metadata update.
* Feat: handle reconnect response to re-configuration PCs.
* Docs: readme manager initial setup.
* Feat: upgrade protocol version to v9.
* Chore: Use participantIdentity instead of Sid for track permissions.
* Feat: Bump flutter-webrtc to 0.9.25.
* Fix: Fix empty label for Wired Headset on Android.
* Fix: ICE Connectivity doesn't establish with DualSIM iPhones.

## 1.2.1

* Fix: fix memory leak for screen capture (macOS).
* Feat: web/native device consistency management (native/web).
* Fix: fix renderer issue for Safari/Firefox.
* Fix: set forceRelay if server response is enabled.
* Feat: Forward leave reason of disconnected events.
* Feat: expose logger level api.
* Feat: expose Room recording event.

## 1.2.0

* Fix: re-publish tracks after re connect
* Fix the bug for firefox.
* Fix crash when using virtual camera (OBS) for osx.
* Fix crash when screen sharing with simulcast on macOS
* Feat: support fast switch camera for LocalVideoTrack.

## 1.1.12

* Fix: Audio output list is empty in android (#231)
* Update flutter-webrtc to 0.9.19
  * As a result of this, the BLUETOOTH_CONNECT permission for Android is no longer needed.

## 1.1.11

* Fix: fix connection fails for firefox. (#222, close #221)

## 1.1.10

* Fix: Disconnect from room before app closes.
* Fix: Correctly throws final error when connection fails.

## 1.1.9

* Bump flutter-webrtc to 0.9.17
* Enable BroadCastExtension for iOS in example.

## 1.1.8

* Fix resume/full-reconnect.
* Support stop audio track on mute(turn off the mic indicator).

## 1.1.7

* Fixed ice config issues. (#192).
* Make timeouts configurable.
* Fixed Hardware.setSpeakerphoneOn() not working on iOS.
* Fixed track not being correctly passed to localParticipant in FastConnectOptions,
  causing the camera to apply twice and not be released.
* Clean up pingIntervalTimer when closing SignalClient.

## 1.1.6

* Supports getting the connected remote address.

## 1.1.5

* Make MediaDevice data class.
* Add simulate for candidate protocol switch.
* Fix VideoTrackRenderer for local has been blacked when toggle video status #166

## 1.1.4

* Fixed timestamp type error in ping/pong.

## 1.1.3

* Add sid for reconnecting. (#168)
* Add force relay config. (#169)
* Bump flutter_webrtc version to 0.9.7.

## 1.1.2

* feat: Support for capturing audio for chrome tab.
* Expose dataChannel for e2e testing.
* Expose RTPReceiver for getting track statistics.
* fix: Do not set mandatory & optional parameters, when used in web (#164)
* fix: fix setSpeakerphoneOn, close #167.

## 1.1.1-hotfix

* Fix compilation error caused by webrtc-interface version jumping.

## 1.1.1

* Add hardware api for camera and audio input/output selection.
* Fixed UI stuck when get thumbnails on screen sharing. (#149)

## 1.1.0-hotfix

* Align the version in .podspec with the package version (fix compilation errors under ios/mac).

## 1.1.0

* Set subscription to allowed when subscribed.
* Handle combined participant update.
* Downgrade version settings to support flutter 2.8.0+.
* Fix: camera release.
* Feat: iOS screen share.
* Feat: Screen sharing for desktop.
* Feat: protocol v8.

## 1.0.1

* Re-send tracks permissions after reconnected.
* Add audioBitrate option for publishAudioTrack.
* Bump version for flutter_webrtc (up to 0.8.9).
* Fix: SIGTERM / Crash on connection (Windows) #121
* Fix: Microphone not published on windows build #64

## 1.0.0

* Ready for Flutter 3.
* `mirrorMode` for `VideoTrackRenderer`.
* Fix url building logic for validation mode.
* Changed `AVAudioSessionCategory` switch timing to publish / unpublish.
* Support for Bluetooth on Android 11.

## 0.5.9

* Fix: iOS audio issue which prevents `AVAudioSessionCategory` to switch correctly.

## 0.5.8

* Support for protocol 7, remote unpublish.
* Fixes simulcast issues with Android devices.
* Adds ability to select capture device by id.
* `serverRegion` property on Room.
* Minor optimizations.

## 0.5.7

* Using WebRTC version M97.
* New track subscription permissions API.
* Improvements to reconnect logic.
* Room metadata update event.

## 0.5.6

* Using WebRTC version M93.
* New `dynacast` option to `RoomOptions`. Dynacast dynamically pauses
  video layers that are not being consumed by any subscribers, significantly
  reducing publishing CPU and bandwidth usage. (currently defaults to off)
* Rename `optimizeVideo` to `adaptiveStream` and improve stability.
  AdaptiveStream lets LiveKit automatically manage quality of subscribed
  video tracks to optimize for bandwidth and CPU.
* Ensure data channel is ready state when `LocalParticipant.publishData` api is called.

## 0.5.5

* Default capture options for setCameraEnabled, setMicrophoneEnabled
* Track stream update events
* Send video layers to server for more video optimization
* Room instance can be created without connecting
* Release Camera/Mic when track is muted
* Better type handling
* Option to unpublish without stopping track
* Fixed RemoteTrackPublication mute events
* Fixed data channel publish bug
* Initial Windows support

## 0.5.4

* Screen sharing support for Android
* Fixed TrackPublication/Track mute status
* Fixed bug with updateTrack
* Fixed being able to apply capture resolution constraints
* Initial macOS support

## 0.5.3

* Connection quality information
* Automatic video optimizations
* Simplified track APIs
* Fix ios camera switch issue
* Looser podspec constraint for WebRTC-SDK to avoid build issues
* Better URL parsing

## 0.5.2

* change ios audio session defaults to support voice isolation
* fix explicit subscribe/unsubscribe issue
* fix WebRTC-SDK resolve issue

## 0.5.1

* include plugins for Android and Web

## 0.5.0

* major update with new event system
* supports simulcast for iOS
* support for background audio for iOS
* support for protocol 3, subscriber as primary connection
* improved audio management for iOS, mic indicator only when audio tracks published
* fires TrackUnpublished for local tracks
* fixed occasional crashes during publishing

## 0.4.1

* fixed video rendering blank after widget changes

## 0.4.0

* fixed audio track playback for web
* fixed publishing tracks for web
* updated constants to be lowerCamelCase
* updated style & formatting guide

## 0.3.0

* `replaceTrack` API to switch camera sources
* example app works on Android

## 0.2.0

* pass more detailed connect error message
* bugfixes with publishing duplicate video tracks
* removed use of media stream during publishing

## 0.1.1

* Minor improvements to error handling

## 0.1.0

* Initial beta release.
