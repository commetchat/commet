// Telling the user when their microphone stopped reaching the call and the
// repairs did not bring it back: nobody hears their own microphone, so
// without this they only find out when someone asks whether they are
// still there.
import 'package:commet/ui/organisms/dj/dj_toast.dart';
import 'package:intl/intl.dart';

String get messageMicrophoneNotGettingThrough => Intl.message(
    "Your microphone stopped reaching the call. Trying to bring it back; if it doesn't come back, check the device or rejoin the call.",
    name: "messageMicrophoneNotGettingThrough",
    desc:
        "Shown during a call when the user's microphone stopped sending audio and the automatic repairs have not brought it back yet");

String get messageMicrophoneBack => Intl.message(
    "Your microphone is reaching the call again.",
    name: "messageMicrophoneBack",
    desc:
        "Shown during a call after the user was told their microphone stopped reaching the call, once it works again");

bool _warned = false;

/// Every repair was tried and the microphone still does not get through.
void warnMicrophoneNotGettingThrough() {
  _warned = true;
  DjToast.show(messageMicrophoneNotGettingThrough, isError: true);
}

/// The microphone works again. Only said to someone who was told it did
/// not.
void noticeMicrophoneBack() {
  if (!_warned) return;
  _warned = false;
  DjToast.show(messageMicrophoneBack);
}
