class CompetitionModel {
  final String id;
  final String name;
  final String? shortName;
  final String competitionType;
  final int year;
  final String category;
  final String gender;
  final String? organizer;
  final String? hostCity;
  final String? hostState;
  final String? startDate;
  final String? endDate;
  final String? participatingTeamsText;
  final int? teamCount;
  final int? advancingTeamCount;
  final String? standingsText;
  final String? notes;
  final bool isPublic;
  final bool isFeaturedForViewer;

  const CompetitionModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.competitionType,
    required this.year,
    required this.category,
    required this.gender,
    required this.organizer,
    required this.hostCity,
    required this.hostState,
    required this.startDate,
    required this.endDate,
    required this.participatingTeamsText,
    required this.teamCount,
    required this.advancingTeamCount,
    required this.standingsText,
    required this.notes,
    required this.isPublic,
    required this.isFeaturedForViewer,
  });

  factory CompetitionModel.fromMap(Map<String, dynamic> map) {
    return CompetitionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      shortName: map['short_name'] as String?,
      competitionType: map['competition_type'] as String? ?? 'outro',
      year: map['year'] as int,
      category: map['category'] as String? ?? 'outro',
      gender: map['gender'] as String? ?? 'misto',
      organizer: map['organizer'] as String?,
      hostCity: map['host_city'] as String?,
      hostState: map['host_state'] as String?,
      startDate: map['start_date']?.toString(),
      endDate: map['end_date']?.toString(),
      participatingTeamsText: map['participating_teams_text'] as String?,
      teamCount: map['team_count'] as int?,
      advancingTeamCount: map['advancing_team_count'] as int?,
      standingsText: map['standings_text'] as String?,
      notes: map['notes'] as String?,
      isPublic: map['is_public'] as bool? ?? false,
      isFeaturedForViewer: map['is_featured_for_viewer'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'short_name': shortName,
      'competition_type': competitionType,
      'year': year,
      'category': category,
      'gender': gender,
      'organizer': organizer,
      'host_city': hostCity,
      'host_state': hostState,
      'start_date': startDate,
      'end_date': endDate,
      'participating_teams_text': participatingTeamsText,
      'team_count': teamCount,
      'advancing_team_count': advancingTeamCount,
      'standings_text': standingsText,
      'notes': notes,
      'is_public': isPublic,
      'is_featured_for_viewer': isFeaturedForViewer,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return toInsertMap();
  }
}
