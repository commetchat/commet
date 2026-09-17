// Opens the soundboard popover above a call control. Disabled while the
// user is deafened, like Discord.
import 'package:commet/client/matrix/components/soundboard/matrix_soundboard_emoji_image.dart';
import 'package:commet/ui/atoms/anchored_popover.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_call_controller.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_popover.dart';
import 'package:flutter/material.dart';

class SoundboardButton extends StatefulWidget {
  final SoundboardCallController controller;
  final bool deafened;
  final PopoverAlignment alignment;
  final ValueChanged<bool>? onOpenChanged;

  /// Builds the actual button; `onPressed` is null while deafened.
  final Widget Function(BuildContext context, VoidCallback? onPressed) builder;

  const SoundboardButton({
    super.key,
    required this.controller,
    required this.deafened,
    required this.builder,
    this.alignment = PopoverAlignment.center,
    this.onOpenChanged,
  });

  @override
  State<SoundboardButton> createState() => _SoundboardButtonState();
}

class _SoundboardButtonState extends State<SoundboardButton> {
  final GlobalKey<AnchoredPopoverState> _popover = GlobalKey();

  @override
  void didUpdateWidget(SoundboardButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deafened && !oldWidget.deafened) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _popover.currentState?.close());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    return AnchoredPopover(
      key: _popover,
      alignment: widget.alignment,
      onOpenChanged: widget.onOpenChanged,
      anchorBuilder: (context, open, toggle) => Tooltip(
        message: widget.deafened
            ? 'Sound effects are disabled while audio is disabled'
            : 'Open sound effects',
        child: widget.builder(context, widget.deafened ? null : toggle),
      ),
      popoverBuilder: (context, close) => ListenableBuilder(
        listenable: ctrl,
        builder: (context, _) => SoundboardPopover(
          sources: ctrl.sources,
          favorites: SoundboardCallController.favorites,
          onPlay: (id) => ctrl.soundboard?.trigger(id),
          volume01: ctrl.volume01,
          onVolumeChanged: ctrl.setVolume01,
          imageFor: (emoji) => soundboardEmojiImage(emoji, ctrl.session.client),
        ),
      ),
    );
  }
}
