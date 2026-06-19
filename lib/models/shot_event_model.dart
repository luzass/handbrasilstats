class ShotEventModel {
  final String id;
  final String matchId;
  final String competitionId;
  final String teamId;
  final String playerId;
  final String? goalkeeperPlayerId;
  final int zoneId;
  final int? goalZoneId;
  final String shotType;
  final String shotResult;
  final String attackContext;
  final String period;
  final int minute;
  final int second;
  final int sequenceOrder;
  final String? createdBy;
  final String? notes;

  const ShotEventModel({
    required this.id,
    required this.matchId,
    required this.competitionId,
    required this.teamId,
    required this.playerId,
    required this.goalkeeperPlayerId,
    required this.zoneId,
    required this.goalZoneId,
    required this.shotType,
    required this.shotResult,
    required this.attackContext,
    required this.period,
    required this.minute,
    required this.second,
    required this.sequenceOrder,
    required this.createdBy,
    required this.notes,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'match_id': matchId,
      'competition_id': competitionId,
      'team_id': teamId,
      'player_id': playerId,
      'goalkeeper_player_id': goalkeeperPlayerId,
      'zone_id': zoneId,
      'goal_zone_id': goalZoneId,
      'shot_type': shotType,
      'shot_result': shotResult,
      'attack_context': attackContext,
      'period': period,
      'minute': minute,
      'second': second,
      'sequence_order': sequenceOrder,
      'created_by': createdBy,
      'notes': notes,
    };
  }
}