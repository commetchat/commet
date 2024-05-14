import 'package:intl/intl.dart';

class CommonStrings {
  static String get promptReply => Intl.message("Reply",
      name: "promptReply", desc: "Generic prompt to reply to a message");

  static String get promptAddReaction => Intl.message("Add Reaction",
      name: "promptAddReaction",
      desc: "Generic prompt to add reaction to a message");

  static String get promptEdit => Intl.message("Edit",
      name: "promptEdit", desc: "Generic prompt to edit something");

  static String get promptOptions => Intl.message("Options",
      name: "promptOptions",
      desc:
          "Generic prompt for options, generally would be used to open a settings menu, extra details or similar");

  static String get promptSettings => Intl.message("Settings",
      name: "promptSettings",
      desc:
          "Generic prompt for settings, usually will open a settings menu or similar");

  static String get promptHome => Intl.message("Home",
      name: "promptHome",
      desc:
          "Generic prompt to go home, usually will go back to a main menu, or similar");

  static String get promptAccept => Intl.message("Accept",
      name: "promptAccept",
      desc:
          "Generic prompt to accept something, probably a request of some kind");

  static String get promptReject => Intl.message("Reject",
      name: "promptReject",
      desc:
          "Generic prompt to reject something, probably a request of some kind");

  static String get promptApply => Intl.message("Apply",
      name: "promptApply",
      desc: "Generic prompt to apply something, probably a setting");

  static String get promptDelete => Intl.message("Delete",
      name: "promptDelete", desc: "Generic prompt to delete something");

  static String get promptDownload => Intl.message("Download",
      name: "promptDownload", desc: "Generic prompt to download something");

  static String get promptJoin => Intl.message("Join",
      name: "promptJoin", desc: "Generic prompt to join a room");

  static String get promptSubmit => Intl.message("Submit",
      name: "promptSubmit", desc: "Generic prompt to submit something");

  static String get promptContinue => Intl.message("Continue",
      name: "promptContinue",
      desc: "Generic prompt to continue with some action");

  static String get promptConfirm => Intl.message("Confirm",
      name: "promptConfirm", desc: "Generic prompt to confirm some action");

  static String get promptDone => Intl.message("Done",
      name: "promptDone", desc: "Generic prompt to confirm that you are done");

  static String get promptReset => Intl.message("Reset",
      name: "promptReset", desc: "Generic prompt to reset something");

  static String get promptEnable => Intl.message("Enable",
      name: "promptEnable", desc: "Generic prompt to enable something");

  static String get promptRestore => Intl.message("Restore",
      name: "promptRestore", desc: "Generic prompt to restore something");

  static String get promptPoliteNo => Intl.message("No, thanks",
      name: "promptPoliteNo",
      desc: "Generic message to decline something, using nice manners :)");

  static String get promptBack => Intl.message("Back",
      desc: "Prompt text to go backwards, probably for navigation",
      name: "promptBack");

  static String get promptCopy =>
      Intl.message("Copy", desc: "Prompt to copy text", name: "promptCopy");

  static String get promptCopyComplete => Intl.message("Copied!",
      desc: "Prompt text for after a copy has been completed",
      name: "promptCopyComplete");

  static String get labelOr => Intl.message("Or",
      desc:
          "Text that is placed between two or more options: [button1] or [button2]",
      name: "labelOr");
}
