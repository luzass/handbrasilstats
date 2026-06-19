import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_statistics_list_item_model.dart';

class MatchStatisticsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MatchStatisticsListItemModel>> getMatches() async {
    final response = await _supabase
        .from('matches')
        .select('''
          id,
          competition_id,
          home_team_id,
          away_team_id,
          score_home,
          score_away,
          status,
          created_at,
          competitions(name),
          home_team:teams!matches_home_team_id_fkey(name, shield_url),
          away_team:teams!matches_away_team_id_fkey(name, shield_url)
        ''')
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => MatchStatisticsListItemModel.fromMap(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMatchLiveStats(String matchId) async {
    final response = await _supabase
        .from('v_match_live_stats')
        .select()
        .eq('match_id', matchId);

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMatchGoalkeeperStats(String matchId) async {
    final response = await _supabase
        .from('v_match_goalkeeper_stats')
        .select()
        .eq('match_id', matchId)
        .order('team_name')
        .order('goalkeeper_name');

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMatchPlayerStats(String matchId) async {
    final response = await _supabase
        .from('v_match_player_stats')
        .select()
        .eq('match_id', matchId)
        .order('team_name')
        .order('player_name');

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMatchPlayerZoneStats(String matchId) async {
    final response = await _supabase
        .from('v_match_player_zone_stats')
        .select()
        .eq('match_id', matchId)
        .order('team_name')
        .order('player_name')
        .order('zone_id');

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMatchPlayerGoalZoneStats(String matchId) async {
    final response = await _supabase
        .from('v_match_player_goal_zone_stats')
        .select()
        .eq('match_id', matchId)
        .order('team_name')
        .order('player_name')
        .order('zone_id')
        .order('goal_zone_id');

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
  Future<List<Map<String, dynamic>>> getMatchGoalkeeperGoalZoneStats(String matchId) async {
  final response = await _supabase
      .from('v_match_goalkeeper_goal_zone_stats')
      .select()
      .eq('match_id', matchId)
      .order('team_name')
      .order('goalkeeper_name')
      .order('zone_id')
      .order('goal_zone_id');

  return (response as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
    }
    Future<List<Map<String, dynamic>>> getAllPlayerZoneStatsByPlayer(String playerId) async {
  final response = await _supabase
      .from('v_player_zone_stats')
      .select()
      .eq('player_id', playerId)
      .order('zone_id');

  return (response as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
}

    Future<List<Map<String, dynamic>>> getAllPlayerGoalZoneStatsByPlayer(String playerId) async {
    final response = await _supabase
        .from('v_match_player_goal_zone_stats')
        .select()
        .eq('player_id', playerId)
        .order('zone_id')
        .order('goal_zone_id');

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    }

    Future<List<Map<String, dynamic>>> getAllGoalkeeperGoalZoneStatsByPlayer(String playerId) async {
    final response = await _supabase
        .from('v_match_goalkeeper_goal_zone_stats')
        .select()
        .eq('player_id', playerId)
        .order('zone_id')
        .order('goal_zone_id');

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    }
}