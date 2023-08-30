import 'package:intl/intl.dart';

class CommonStrings {
  static String get promptReply =>
      Intl.message("Reply", desc: "Generic prompt to reply to a message");

  static String get promptAddReaction => Intl.message("Add Reaction",
      desc: "Generic prompt to add reaction to a message");

  static String get promptEdit =>
      Intl.message("Edit", desc: "Generic prompt to edit something");

  static String get promptOptions => Intl.message("Options",
      desc:
          "Generic prompt for options, generally would be used to open a settings menu, extra details or similar");

  static String get promptSettings => Intl.message("Settings",
      desc:
          "Generic prompt for settings, usually will open a settings menu or similar");

  static String get promptHome => Intl.message("Home",
      desc:
          "Generic prompt to go home, usually will go back to a main menu, or similar");

  static String get promptAccept => Intl.message("Accept",
      desc:
          "Generic prompt to accept something, probably a request of some kind");

  static String get promptReject => Intl.message("Reject",
      desc:
          "Generic prompt to reject something, probably a request of some kind");

  static String get promptApply => Intl.message("Apply",
      desc: "Generic prompt to apply something, probably a setting");

  static String get promptDelete =>
      Intl.message("Delete", desc: "Generic prompt to delete something");
}
