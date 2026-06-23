class PlayerCsvImportResult {
  final int createdCount;
  final int updatedCount;
  final int rosterLinkedCount;
  final int rosterReactivatedCount;
  final int skippedCount;
  final List<String> errors;

  const PlayerCsvImportResult({
    required this.createdCount,
    required this.updatedCount,
    required this.rosterLinkedCount,
    required this.rosterReactivatedCount,
    required this.skippedCount,
    required this.errors,
  });
}
