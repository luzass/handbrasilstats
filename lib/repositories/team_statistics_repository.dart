import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_goal_zone_breakdown_model.dart';

class TeamStatisticsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTeams() async {
    final response = await _supabase
        .from('teams')
        .select('id, name, shield_url')
        .order('name', ascending: true);

    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> getTeamGeneralStats(String teamId) async {
    final response = await _supabase
        .from('v_team_competition_stats')
        .select()
        .eq('team_id', teamId);

    final rows = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (rows.isEmpty) return null;

    num shots = 0;
    num goals7m = 0;
    num shots7m = 0;
    num shots6m = 0;
    num goals6m = 0;
    num shots9m = 0;
    num goals9m = 0;
    num shotsOut = 0;
    num goalsScored = 0;

    for (final row in rows) {
      shots += (row['shots'] as num?) ?? 0;
      goals7m += (row['goals_7m'] as num?) ?? 0;
      shots7m += (row['shots_7m'] as num?) ?? 0;
      shots6m += (row['shots_6m'] as num?) ?? 0;
      goals6m += (row['goals_6m'] as num?) ?? 0;
      shots9m += (row['shots_9m'] as num?) ?? 0;
      goals9m += (row['goals_9m'] as num?) ?? 0;
      shotsOut += (row['shots_out'] as num?) ?? 0;
      goalsScored += (row['goals_scored'] as num?) ?? 0;
    }

    double safePct(num a, num b) => b == 0 ? 0 : ((a / b) * 100);

    return {
      'shots': shots,
      'goals_scored': goalsScored,
      'shots_out': shotsOut,
      'shots_7m': shots7m,
      'goals_7m': goals7m,
      'shot_percentage_7m': safePct(goals7m, shots7m),
      'shots_6m': shots6m,
      'goals_6m': goals6m,
      'shot_percentage_6m': safePct(goals6m, shots6m),
      'shots_9m': shots9m,
      'goals_9m': goals9m,
      'shot_percentage_9m': safePct(goals9m, shots9m),
      'shot_percentage': safePct(goalsScored, shots),
    };
  }

  Future<List<Map<String, dynamic>>> getTeamPlayers(String teamId) async {
    final response = await _supabase
        .from('v_team_player_stats_total')
        .select()
        .eq('team_id', teamId)
        .order('player_name');

    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTeamGoalkeepers(String teamId) async {
    final response = await _supabase
        .from('v_team_goalkeeper_stats_total')
        .select()
        .eq('team_id', teamId)
        .order('goalkeeper_name');

    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTeamShotEvents(String teamId) async {
    final response = await _supabase
        .from('shot_events')
        .select('player_id, shot_result')
        .eq('team_id', teamId);

    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<MatchGoalZoneBreakdownModel>> getTeamGoalBreakdown({
    required String teamId,
    int? shotZoneId,
  }) async {
    final response = await _supabase.rpc(
      'get_team_goal_zone_breakdown',
      params: {
        'p_team_id': teamId,
        'p_zone_id': shotZoneId,
      },
    );

    return (response as List)
        .map((item) => MatchGoalZoneBreakdownModel.fromMap(item))
        .toList();
  }

  Future<List<MatchGoalZoneBreakdownModel>> getTeamGoalkeeperBreakdown({
    required String teamId,
    int? shotZoneId,
  }) async {
    final response = await _supabase.rpc(
      'get_team_goalkeeper_goal_zone_breakdown',
      params: {
        'p_team_id': teamId,
        'p_zone_id': shotZoneId,
      },
    );

    return (response as List)
        .map((item) => MatchGoalZoneBreakdownModel.fromMap(item))
        .toList();
  }
}
