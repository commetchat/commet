const String pronounsFieldKey = "io.fsky.nyx.pronouns";

List<String> parsePronounsField(Object? value) {
  if (value is! List) return const [];

  return value
      .map((entry) => entry is Map ? entry["summary"] : null)
      .whereType<String>()
      .where((summary) => summary.isNotEmpty)
      .toList();
}
