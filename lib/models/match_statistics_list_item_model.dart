class MatchStatisticsListItemModel {
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
  final String? status;
  final DateTime? matchDate;

  const MatchStatisticsListItemModel({
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
    required this.matchDate,
  });

  factory MatchStatisticsListItemModel.fromMap(Map<String, dynamic> map) {
    return MatchStatisticsListItemModel(
      id: map['id'] as String,
      competitionId: map['competition_id'] as String,
      competitionName: (map['competitions']?['name'] as String?) ?? 'Sem competição',
      homeTeamId: map['home_team_id'] as String,
      homeTeamName: (map['home_team']?['name'] as String?) ?? 'Time A',
      homeTeamShieldUrl: map['home_team']?['shield_url'] as String?,
      awayTeamId: map['away_team_id'] as String,
      awayTeamName: (map['away_team']?['name'] as String?) ?? 'Time B',
      awayTeamShieldUrl: map['away_team']?['shield_url'] as String?,
      scoreHome: map['score_home'] as int? ?? 0,
      scoreAway: map['score_away'] as int? ?? 0,
      status: map['status'] as String?,
      matchDate: map['created_at'] != null
        ? DateTime.tryParse(map['created_at'] as String)
        : null,
    );
  }
}