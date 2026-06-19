class MatchEventModel {
  final String id;
  final String matchId;
  final String competitionId;
  final String teamId;
  final String? playerId;
  final String eventType;
  final String? period;
  final int? minute;
  final int? second;
  final int sequenceOrder;
  final String? createdBy;
  final String? notes;

  const MatchEventModel({
    required this.id,
    required this.matchId,
    required this.competitionId,
    required this.teamId,
    required this.playerId,
    required this.eventType,
    required this.period,
    required this.minute,
    required this.second,
    required this.sequenceOrder,
    required this.createdBy,
    required this.notes,
  });

  factory MatchEventModel.fromMap(Map<String, dynamic> map) {
    return MatchEventModel(
      id: map['id'] as String,
      matchId: map['match_id'] as String,
      competitionId: map['competition_id'] as String,
      teamId: map['team_id'] as String,
      playerId: map['player_id'] as String?,
      eventType: map['event_type'] as String,
      period: map['period'] as String?,
      minute: map['minute'] as int?,
      second: map['second'] as int?,
      sequenceOrder: map['sequence_order'] as int? ?? 1,
      createdBy: map['created_by'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'match_id': matchId,
      'competition_id': competitionId,
      'team_id': teamId,
      'player_id': playerId,
      'event_type': eventType,
      'period': period,
      'minute': minute,
      'second': second,
      'sequence_order': sequenceOrder,
      'created_by': createdBy,
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'team_id': teamId,
      'player_id': playerId,
      'event_type': eventType,
      'period': period,
      'minute': minute,
      'second': second,
      'notes': notes,
    };
  }
}