class TeamModel {
  final String id;
  final String name;
  final String? shortName;
  final String category;
  final String gender;
  final int? foundingYear;
  final String? city;
  final String? state;
  final String? country;
  final String? shieldUrl;
  final String? coachName;
  final bool isActive;

  const TeamModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.gender,
    required this.foundingYear,
    required this.city,
    required this.state,
    required this.country,
    required this.shieldUrl,
    required this.coachName,
    required this.isActive,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    return TeamModel(
      id: map['id'] as String,
      name: map['name'] as String,
      shortName: map['short_name'] as String?,
      category: map['category'] as String? ?? 'outro',
      gender: map['gender'] as String? ?? 'misto',
      foundingYear: map['founding_year'] as int?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      country: map['country'] as String?,
      shieldUrl: map['shield_url'] as String?,
      coachName: map['coach_name'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'short_name': shortName,
      'category': category,
      'gender': gender,
      'founding_year': foundingYear,
      'city': city,
      'state': state,
      'country': country,
      'shield_url': shieldUrl,
      'coach_name': coachName,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return toInsertMap();
  }
}