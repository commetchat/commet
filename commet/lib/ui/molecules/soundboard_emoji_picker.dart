// Soundboard sound icon: display widget and the emoji picker popover used to
// choose it (Space emoticons + unicode emoji), Discord style.
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/soundboard/soundboard_emoji.dart';
import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/utils/autofill_utils.dart';
import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

/// Resolves the image of a custom [SoundboardEmoji], or null when it can't be
/// rendered (no client, not custom).
typedef SoundboardEmojiImageResolver = ImageProvider? Function(
    SoundboardEmoji emoji);

/// The sound icon a picked [emoticon] stands for. Custom emoticons are
/// referenced by their mxc image, which is their [Emoticon.key].
SoundboardEmoji soundboardEmojiFromEmoticon(Emoticon emoticon) {
  if (emoticon.image != null && emoticon.key.startsWith('mxc://')) {
    return SoundboardEmoji.custom(mxc: emoticon.key, shortcode: emoticon.slug);
  }
  return SoundboardEmoji.unicode(emoticon.slug);
}

/// Renders a sound icon: the custom emoticon image when [image] is given,
/// otherwise the unicode emoji (or its fallback).
class SoundboardEmojiView extends StatelessWidget {
  final SoundboardEmoji emoji;
  final ImageProvider? image;
  final double size;

  const SoundboardEmojiView(this.emoji,
      {super.key, this.image, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final text = Text(emoji.unicode, style: TextStyle(fontSize: size));
    final image = emoji.isCustom ? this.image : null;
    if (image == null) return text;
    // Emoji glyphs render a bit taller than their font size.
    final extent = size * 1.2;
    return Tooltip(
      message: emoji.shortcode ?? '',
      child: Image(
        image: image,
        width: extent,
        height: extent,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => text,
      ),
    );
  }
}

/// Button showing the current sound icon. Tapping it opens a popover with
/// [packs] (Space emoticons first, then unicode) and a shortcode search.
class SoundboardEmojiPickerButton extends StatefulWidget {
  final SoundboardEmoji value;
  final List<EmoticonPack> packs;
  final ValueChanged<SoundboardEmoji> onChanged;
  final SoundboardEmojiImageResolver? imageFor;

  const SoundboardEmojiPickerButton({
    super.key,
    required this.value,
    required this.packs,
    required this.onChanged,
    this.imageFor,
  });

  @override
  State<SoundboardEmojiPickerButton> createState() =>
      _SoundboardEmojiPickerButtonState();
}

class _SoundboardEmojiPickerButtonState
    extends State<SoundboardEmojiPickerButton> {
  final _controller = JustTheController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(Emoticon emoticon) {
    _controller.hideTooltip();
    widget.onChanged(soundboardEmojiFromEmoticon(emoticon));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Keep the popover inside small windows and dialogs.
    final screen = MediaQuery.sizeOf(context);
    final width = (screen.width - 16).clamp(0.0, 400.0);
    final height = (screen.height - 16).clamp(0.0, 420.0);
    return JustTheTooltip(
      isModal: true,
      triggerMode: TooltipTriggerMode.manual,
      preferredDirection: AxisDirection.down,
      controller: _controller,
      backgroundColor: colors.surfaceContainerLow,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: colors.surfaceContainerLow,
          child: SizedBox(
            width: width,
            height: height,
            child: EmojiPicker(
              widget.packs,
              onlyEmoji: true,
              size: 38,
              packButtonSize: 38,
              onEmoticonPressed: _pick,
              searchDelegate: (text) => AutofillUtils.searchEmoticonPacks(
                  text, widget.packs,
                  limit: 50),
            ),
          ),
        ),
      ),
      child: Tooltip(
        message: 'Choose emoji',
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(56, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: () => _controller.showTooltip(),
          child: SoundboardEmojiView(
            widget.value,
            image: widget.imageFor?.call(widget.value),
          ),
        ),
      ),
    );
  }
}
