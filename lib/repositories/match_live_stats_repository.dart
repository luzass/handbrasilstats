import 'package:supabase_flutter/supabase_flutter.dart';

class MatchLiveStatsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMatchLiveStats(String matchId) async {
    final response = await _supabase
        .from('v_match_live_stats')
        .select()
        .eq('match_id', matchId);

    return List<Map<String, dynamic>>.from(response);
  }
}