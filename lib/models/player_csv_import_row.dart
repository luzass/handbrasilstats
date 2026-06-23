class PlayerCsvImportRow {
  final int sourceRowNumber;
  final String fullName;
  final String? cpf;
  final String? birthDate;
  final double? heightCm;
  final String? birthCity;
  final String? dominantHand;
  final String? primaryPosition;
  final String? titlesText;
  final bool? isActive;

  const PlayerCsvImportRow({
    required this.sourceRowNumber,
    required this.fullName,
    required this.cpf,
    required this.birthDate,
    required this.heightCm,
    required this.birthCity,
    required this.dominantHand,
    required this.primaryPosition,
    required this.titlesText,
    required this.isActive,
  });
}
