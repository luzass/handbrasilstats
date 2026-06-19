import 'package:supabase_flutter/supabase_flutter.dart';

class TeamRosterRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Set<String>> getActivePlayerIds(String teamId) async {
    final response = await _supabase
        .from('team_players')
        .select('player_id')
        .eq('team_id', teamId)
        .eq('is_active', true);

    return (response as List)
        .map((item) => item['player_id'] as String)
        .toSet();
  }

  Future<void> addPlayerToTeam({
    required String teamId,
    required String playerId,
  }) async {
    final response = await _supabase
        .from('team_players')
        .select('player_id')
        .eq('team_id', teamId)
        .eq('player_id', playerId);

    final existingRows = response as List;

    if (existingRows.isEmpty) {
      await _supabase.from('team_players').insert({
        'team_id': teamId,
        'player_id': playerId,
        'is_active': true,
      });
      return;
    }

    await _supabase
        .from('team_players')
        .update({'is_active': true})
        .eq('team_id', teamId)
        .eq('player_id', playerId);
  }

  Future<void> removePlayerFromTeam({
    required String teamId,
    required String playerId,
  }) async {
    await _supabase
        .from('team_players')
        .update({'is_active': false})
        .eq('team_id', teamId)
        .eq('player_id', playerId);
  }
}
