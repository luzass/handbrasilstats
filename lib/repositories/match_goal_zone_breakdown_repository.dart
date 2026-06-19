import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_goal_zone_breakdown_model.dart';

class MatchGoalZoneBreakdownRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MatchGoalZoneBreakdownModel>> getPlayerBreakdown({
    required String matchId,
    required String playerId,
    int? shotZoneId,
  }) async {
    final response = await _supabase.rpc(
      'get_match_player_goal_zone_breakdown',
      params: {
        'p_match_id': matchId,
        'p_player_id': playerId,
        'p_zone_id': shotZoneId,
      },
    );

    return (response as List)
        .map((item) => MatchGoalZoneBreakdownModel.fromMap(item))
        .toList();
  }

  Future<List<MatchGoalZoneBreakdownModel>> getGoalkeeperBreakdown({
    required String matchId,
    required String goalkeeperId,
    int? shotZoneId,
  }) async {
    final response = await _supabase.rpc(
      'get_match_goalkeeper_goal_zone_breakdown',
      params: {
        'p_match_id': matchId,
        'p_goalkeeper_id': goalkeeperId,
        'p_zone_id': shotZoneId,
      },
    );

    return (response as List)
        .map((item) => MatchGoalZoneBreakdownModel.fromMap(item))
        .toList();
  }
}