class ViewerMatchModel {
  final String id;
  final String competitionId;
  final String competitionName;
  final String homeTeamId;
  final String homeTeamName;
  final String? homeTeamShieldUrl;
  final String awayTeamId;
  final String awayTeamName;
  final String? awayTeamShieldUrl;
  final int scoreHome;
  final int scoreAway;
  final String status;
  final String scoutStatus;
  final String? matchDatetime;
  final String? currentPeriod;
  final int? currentMinute;
  final int? currentSecond;

  const ViewerMatchModel({
    required this.id,
    required this.competitionId,
    required this.competitionName,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeTeamShieldUrl,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.awayTeamShieldUrl,
    required this.scoreHome,
    required this.scoreAway,
    required this.status,
    required this.scoutStatus,
    required this.matchDatetime,
    required this.currentPeriod,
    required this.currentMinute,
    required this.currentSecond,
  });

  factory ViewerMatchModel.fromMap(Map<String, dynamic> map) {
    return ViewerMatchModel(
      id: map['id'] as String,
      competitionId: map['competition_id'] as String,
      competitionName:
          (map['competitions']?['name'] as String?) ?? 'Competicao',
      homeTeamId: map['home_team_id'] as String,
      homeTeamName: (map['home_team']?['name'] as String?) ?? 'Time A',
      homeTeamShieldUrl: map['home_team']?['shield_url'] as String?,
      awayTeamId: map['away_team_id'] as String,
      awayTeamName: (map['away_team']?['name'] as String?) ?? 'Time B',
      awayTeamShieldUrl: map['away_team']?['shield_url'] as String?,
      scoreHome: map['score_home'] as int? ?? 0,
      scoreAway: map['score_away'] as int? ?? 0,
      status: map['status'] as String? ?? 'agendado',
      scoutStatus: map['scout_status'] as String? ?? 'nao_iniciado',
      matchDatetime: map['match_datetime']?.toString(),
      currentPeriod: map['current_period']?.toString(),
      currentMinute: map['current_minute'] as int?,
      currentSecond: map['current_second'] as int?,
    );
  }
}
