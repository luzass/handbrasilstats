class PlayerModel {
  final String id;
  final String? cpf;
  final String fullName;
  final String? birthDate;
  final double? heightCm;
  final String? birthCity;
  final String? photoUrl;
  final String dominantHand;
  final String primaryPosition;
  final String? titlesText;
  final bool isActive;

  const PlayerModel({
    required this.id,
    required this.cpf,
    required this.fullName,
    required this.birthDate,
    required this.heightCm,
    required this.birthCity,
    required this.photoUrl,
    required this.dominantHand,
    required this.primaryPosition,
    required this.titlesText,
    required this.isActive,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] as String,
      cpf: map['cpf'] as String?,
      fullName: map['full_name'] as String,
      birthDate: map['birth_date']?.toString(),
      heightCm: map['height_cm'] == null
          ? null
          : (map['height_cm'] as num).toDouble(),
      birthCity: map['birth_city'] as String?,
      photoUrl: map['photo_url'] as String?,
      dominantHand: map['dominant_hand'] as String? ?? 'nao_informado',
      primaryPosition: map['primary_position'] as String? ?? 'nao_informado',
      titlesText: map['titles_text'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'cpf': cpf,
      'full_name': fullName,
      'birth_date': birthDate,
      'height_cm': heightCm,
      'birth_city': birthCity,
      'photo_url': photoUrl,
      'dominant_hand': dominantHand,
      'primary_position': primaryPosition,
      'titles_text': titlesText,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return toInsertMap();
  }
}