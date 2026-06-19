class MatchModel {
  final String id;
  final String competitionId;
  final String homeTeamId;
  final String awayTeamId;
  final String? matchDatetime;
  final String? venueName;
  final String? venueCity;
  final String? venueState;
  final String status;
  final String scoutStatus;
  final String? currentPeriod;
  final int? currentMinute;
  final int? currentSecond;
  final int scoreHome;
  final int scoreAway;
  final String? notes;

  const MatchModel({
    required this.id,
    required this.competitionId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.matchDatetime,
    required this.venueName,
    required this.venueCity,
    required this.venueState,
    required this.status,
    required this.scoutStatus,
    required this.currentPeriod,
    required this.currentMinute,
    required this.currentSecond,
    required this.scoreHome,
    required this.scoreAway,
    required this.notes,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      id: map['id'] as String,
      competitionId: map['competition_id'] as String,
      homeTeamId: map['home_team_id'] as String,
      awayTeamId: map['away_team_id'] as String,
      matchDatetime: map['match_datetime']?.toString(),
      venueName: map['venue_name'] as String?,
      venueCity: map['venue_city'] as String?,
      venueState: map['venue_state'] as String?,
      status: map['status'] as String? ?? 'agendado',
      scoutStatus: map['scout_status'] as String? ?? 'nao_iniciado',
      currentPeriod: map['current_period']?.toString(),
      currentMinute: map['current_minute'] as int?,
      currentSecond: map['current_second'] as int?,
      scoreHome: map['score_home'] as int? ?? 0,
      scoreAway: map['score_away'] as int? ?? 0,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'competition_id': competitionId,
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'match_datetime': matchDatetime,
      'venue_name': venueName,
      'venue_city': venueCity,
      'venue_state': venueState,
      'status': status,
      'scout_status': scoutStatus,
      'current_period': currentPeriod,
      'current_minute': currentMinute,
      'current_second': currentSecond,
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'competition_id': competitionId,
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'match_datetime': matchDatetime,
      'venue_name': venueName,
      'venue_city': venueCity,
      'venue_state': venueState,
      'status': status,
      'scout_status': scoutStatus,
      'current_period': currentPeriod,
      'current_minute': currentMinute,
      'current_second': currentSecond,
      'notes': notes,
    };
  }
}