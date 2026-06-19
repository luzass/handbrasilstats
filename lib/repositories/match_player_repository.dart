import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_player_model.dart';

class MatchPlayerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MatchPlayerModel>> getMatchPlayers(String matchId) async {
    final response = await _supabase
        .from('match_players')
        .select()
        .eq('match_id', matchId)
        .order('team_id', ascending: true)
        .order('shirt_number', ascending: true);

    return (response as List)
        .map((item) => MatchPlayerModel.fromMap(item))
        .toList();
  }

  Future<void> createMatchPlayer(MatchPlayerModel matchPlayer) async {
    await _supabase.from('match_players').insert(matchPlayer.toInsertMap());
  }

  Future<void> updateMatchPlayer(MatchPlayerModel matchPlayer) async {
    await _supabase
        .from('match_players')
        .update(matchPlayer.toUpdateMap())
        .eq('id', matchPlayer.id);
  }
}