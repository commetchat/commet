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
}
