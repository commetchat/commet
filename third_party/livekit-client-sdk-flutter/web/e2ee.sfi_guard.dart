const MAX_SIF_COUNT = 100;
const MAX_SIF_DURATION = 2000;

class SifGuard {
  int consecutiveSifCount = 0;

  int? sifSequenceStartedAt;

  int lastSifReceivedAt = 0;

  int userFramesSinceSif = 0;

  void recordSif() {
    consecutiveSifCount += 1;
    sifSequenceStartedAt ??= DateTime.timestamp().millisecondsSinceEpoch;
    lastSifReceivedAt = DateTime.timestamp().millisecondsSinceEpoch;
  }

  void recordUserFrame() {
    if (sifSequenceStartedAt == null) {
      return;
    } else {
      userFramesSinceSif += 1;
    }
    if (
        // reset if we received more user frames than SIFs
        userFramesSinceSif > consecutiveSifCount ||
            // also reset if we got a new user frame and the latest SIF frame hasn't been updated in a while
            DateTime.timestamp().millisecondsSinceEpoch - lastSifReceivedAt > MAX_SIF_DURATION) {
      reset();
    }
  }

  bool isSifAllowed() {
    return consecutiveSifCount < MAX_SIF_COUNT &&
        (sifSequenceStartedAt == null ||
            DateTime.timestamp().millisecondsSinceEpoch - sifSequenceStartedAt! < MAX_SIF_DURATION);
  }

  void reset() {
    userFramesSinceSif = 0;
    consecutiveSifCount = 0;
    sifSequenceStartedAt = null;
  }
}
