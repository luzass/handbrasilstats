class MatchRosterLoadResult {
  final int addedCount;
  final int skippedCount;
  final int removedCount;

  const MatchRosterLoadResult({
    required this.addedCount,
    required this.skippedCount,
    required this.removedCount,
  });
}
