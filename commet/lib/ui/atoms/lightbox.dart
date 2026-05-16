import 'dart:async';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/molecules/video_player/video_player.dart';
import 'package:commet/ui/molecules/video_player/video_player_controller.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/popup_dialog.dart';
import 'dart:ui' as ui;

class Lightbox extends StatefulWidget {
  const Lightbox({
    this.image,
    this.video,
    this.thumbnail,
    this.aspectRatio,
    this.contentKey,
    this.customWidget,
    this.videoController,
    super.key,
  });
  final ImageProvider? image;
  final FileProvider? video;
  final ImageProvider? thumbnail;
  final VideoPlayerController? videoController;
  final Widget? customWidget;
  final double? aspectRatio;
  final Key? contentKey;

  @override
  State<Lightbox> createState() => _LightboxState();

  static Future<void> show(
    BuildContext context, {
    ImageProvider? image,
    ImageProvider? thumbnail,
    FileProvider? video,
    Widget? customWidget,
    VideoPlayerController? videoController,
    double? aspectRatio,
    Key? key,
  }) {
    return showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: "LIGHTBOX",
        barrierColor: PopupDialog.barrierColor,
        pageBuilder: (context, _, __) {
          return Lightbox(
            image: image,
            video: video,
            videoController: videoController,
            aspectRatio: aspectRatio,
            thumbnail: thumbnail,
            contentKey: key,
            customWidget: customWidget,
            key: GlobalKey(),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
                      .animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ));
  }
}

class _LightboxState extends State<Lightbox> with TickerProviderStateMixin {
  double aspectRatio = 1;
  bool dismissing = false;
  final controller = TransformationController();
  bool loadingHighQuality = false;

  StreamSubscription? onLodChanged;

  bool rotate = false;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 850),
    vsync: this,
  );

  late final Animation<double> rotationAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  ).drive(Tween(begin: -0.25, end: 0.0));

  late final Animation<double> scaleAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  ).drive(Tween(begin: 0.6, end: 1.0));

  late final Animation<double> rotation =
      ConstantTween(0.0).animate(_controller);
  late final Animation<double> scale = ConstantTween(1.0).animate(_controller);

  @override
  void dispose() {
    onLodChanged?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _controller.stop(canceled: true);

    if (widget.aspectRatio != null) {
      aspectRatio = widget.aspectRatio!;
    }

    if (widget.image != null) {
      getImageInfo();
    }

    if (widget.video != null) {
      getVideoInfo();
    }

    if (widget.image case LODImageProvider lod) {
      onLodChanged = lod.onLODChanged.listen((_) {
        getImageInfo();
      });

      loadingHighQuality = true;
      lod.fetchFullRes().then((_) {
        if (mounted) {
          getImageInfo();

          setState(() {
            loadingHighQuality = false;
          });
        }
      });
    }
  }

  void getImageInfo() async {
    var image = await getImage();
    setState(() {
      aspectRatio = image.width / image.height;
    });

    shouldRotate();
  }

  void getVideoInfo() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.aspectRatio != null) {
        shouldRotate();
      }

      var size = await widget.videoController?.getSize();
      print(size);
      if (size != null) {
        setState(() {
          aspectRatio = size.width / size.height;
        });
      }

      shouldRotate();
    });
  }

  double counterRotation = 0.25;

  void shouldRotate() {
    if (!Layout.mobile) {
      return;
    }

    if (widget.image != null && preferences.autoRotateImages.value == false) {
      return;
    }

    if (widget.video != null && preferences.autoRotateVideos.value == false) {
      return;
    }

    var size = MediaQuery.sizeOf(context);
    var screenRatio = size.width / size.height;
    bool prevValue = rotate;
    setState(() {
      rotate = (aspectRatio < 1 && screenRatio > 1) ||
          (aspectRatio > 1 && screenRatio < 1);
    });

    if (rotate != prevValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.value = 0;
        _controller.animateTo(1);
      });
    }
  }

  Future<ui.Image> getImage() {
    Completer<ui.Image> completer = Completer<ui.Image>();

    widget.image!
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, synchronousCall) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    }));
    return completer.future;
  }

  void dismiss() {
    setState(() {
      dismissing = true;
    });
    Navigator.pop(context, widget.contentKey);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        dismiss();
      },
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(BuildConfig.MOBILE ? 10 : 100.0),
          child: ScaledSafeArea(
            child: RotatedBox(
              quarterTurns: rotate ? 1 : 0,
              child: ScaleTransition(
                scale: rotate ? scaleAnimation : scale,
                child: RotationTransition(
                  turns: rotate ? rotationAnimation : rotation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: InteractiveViewer(
                      trackpadScrollCausesScale: true,
                      transformationController: controller,
                      maxScale: 3.5,
                      child: Container(
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GestureDetector(
                            onTap: () {},
                            child: AspectRatio(
                                aspectRatio: aspectRatio,
                                child: widget.customWidget ??
                                    (widget.image != null
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image(
                                                fit: BoxFit.cover,
                                                image: widget.image!,
                                                isAntiAlias: true,
                                                filterQuality:
                                                    FilterQuality.medium,
                                              ),
                                              if (loadingHighQuality)
                                                Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Container(
                                                        decoration: BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .surfaceContainer,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: SizedBox(
                                                              width: 12,
                                                              height: 12,
                                                              child:
                                                                  CircularProgressIndicator()),
                                                        )),
                                                  ),
                                                )
                                            ],
                                          )
                                        : widget.video != null
                                            ? dismissing
                                                ? widget.thumbnail != null
                                                    ? Image(
                                                        fit: BoxFit.cover,
                                                        image:
                                                            widget.thumbnail!,
                                                      )
                                                    : Container(
                                                        color: Colors.black,
                                                      )
                                                : VideoPlayer(
                                                    widget.video!,
                                                    controller:
                                                        widget.videoController,
                                                    showProgressBar: true,
                                                    canGoFullscreen: false,
                                                    thumbnail: widget.thumbnail,
                                                    key: widget.contentKey,
                                                  )
                                            : const Placeholder())),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
