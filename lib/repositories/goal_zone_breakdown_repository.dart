import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/goal_zone_breakdown_model.dart';

class GoalZoneBreakdownRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<GoalZoneBreakdownModel>> getPlayerBreakdown({
    required String playerId,
    required int shotZoneId,
  }) async {
    final response = await _supabase.rpc(
      'get_player_goal_zone_breakdown',
      params: {
        'p_player_id': playerId,
        'p_zone_id': shotZoneId,
      },
    );

    return (response as List)
        .map((item) => GoalZoneBreakdownModel.fromMap(item))
        .toList();
  }

  Future<List<GoalZoneBreakdownModel>> getGoalkeeperBreakdown({
    required String goalkeeperId,
    required int shotZoneId,
  }) async {
    final response = await _supabase.rpc(
      'get_goalkeeper_goal_zone_breakdown',
      params: {
        'p_goalkeeper_id': goalkeeperId,
        'p_zone_id': shotZoneId,
      },
    );

    return (response as List)
        .map((item) => GoalZoneBreakdownModel.fromMap(item))
        .toList();
  }
}
