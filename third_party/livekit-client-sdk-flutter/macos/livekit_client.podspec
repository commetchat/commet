Pod::Spec.new do |s|
  s.name                = 'livekit_client'
  s.version             = '2.7.0'
  s.summary             = 'Open source platform for real-time audio and video.'
  s.description         = 'Open source platform for real-time audio and video.'
  s.homepage            = 'https://livekit.io/'
  s.license             = { :file => '../LICENSE' }
  s.author              = { 'LiveKit' => 'contact@livekit.io' }
  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.platform            = :osx, '10.15'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version       = '5.0'
  s.static_framework    = true

  s.dependency 'FlutterMacOS'
  s.dependency 'WebRTC-SDK', '144.7559.01'
  s.dependency 'flutter_webrtc'
end
