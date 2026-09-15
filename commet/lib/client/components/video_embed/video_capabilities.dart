class VideoCapabilities {
  final bool supportsPlaybackRate;
  final bool supportsQualitySelection;
  final bool supportsCaptions;
  final bool supportsVolume;
  final bool supportsFullscreen;
  final bool supportsCustomControls;
  final bool supportsSeeking;

  const VideoCapabilities({
    this.supportsPlaybackRate = false,
    this.supportsQualitySelection = false,
    this.supportsCaptions = false,
    this.supportsVolume = false,
    this.supportsFullscreen = true,
    this.supportsCustomControls = false,
    this.supportsSeeking = false,
  });

  static const VideoCapabilities native = VideoCapabilities(
    supportsPlaybackRate: true,
    supportsQualitySelection: true,
    supportsCaptions: true,
    supportsVolume: true,
    supportsFullscreen: true,
    supportsCustomControls: true,
    supportsSeeking: true,
  );

  static const VideoCapabilities officialEmbed = VideoCapabilities(
    supportsPlaybackRate: false,
    supportsQualitySelection: false,
    supportsCaptions: false,
    supportsVolume: false,
    supportsFullscreen: true,
    supportsCustomControls: false,
    supportsSeeking: false,
  );
}
