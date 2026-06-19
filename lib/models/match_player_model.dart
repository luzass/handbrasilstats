class MatchPlayerModel {
  final String id;
  final String matchId;
  final String teamId;
  final String playerId;
  final int? shirtNumber;
  final bool isGoalkeeper;
  final String positionInMatch;
  final bool isActiveInMatch;

  const MatchPlayerModel({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.playerId,
    required this.shirtNumber,
    required this.isGoalkeeper,
    required this.positionInMatch,
    required this.isActiveInMatch,
  });

  factory MatchPlayerModel.fromMap(Map<String, dynamic> map) {
    return MatchPlayerModel(
      id: map['id'] as String,
      matchId: map['match_id'] as String,
      teamId: map['team_id'] as String,
      playerId: map['player_id'] as String,
      shirtNumber: map['shirt_number'] as int?,
      isGoalkeeper: map['is_goalkeeper'] as bool? ?? false,
      positionInMatch: map['position_in_match'] as String? ?? 'nao_informado',
      isActiveInMatch: map['is_active_in_match'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'match_id': matchId,
      'team_id': teamId,
      'player_id': playerId,
      'shirt_number': shirtNumber,
      'is_goalkeeper': isGoalkeeper,
      'position_in_match': positionInMatch,
      'is_active_in_match': isActiveInMatch,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'shirt_number': shirtNumber,
      'is_goalkeeper': isGoalkeeper,
      'position_in_match': positionInMatch,
      'is_active_in_match': isActiveInMatch,
    };
  }
}