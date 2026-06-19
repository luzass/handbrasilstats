class GoalZoneBreakdownModel {
  final int goalZoneId;
  final int totalShots;
  final int totalGoals;
  final int totalSaves;
  final double percentage;

  const GoalZoneBreakdownModel({
    required this.goalZoneId,
    required this.totalShots,
    required this.totalGoals,
    required this.totalSaves,
    required this.percentage,
  });

  factory GoalZoneBreakdownModel.fromMap(Map<String, dynamic> map) {
    return GoalZoneBreakdownModel(
      goalZoneId: (map['goal_zone_id'] as num?)?.toInt() ?? 0,
      totalShots: (map['total_shots'] as num?)?.toInt() ?? 0,
      totalGoals: (map['total_goals'] as num?)?.toInt() ?? 0,
      totalSaves: (map['total_saves'] as num?)?.toInt() ?? 0,
      percentage: ((map['percentage'] as num?) ?? 0).toDouble(),
    );
  }
}