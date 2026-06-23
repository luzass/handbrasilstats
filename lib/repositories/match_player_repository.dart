import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_roster_load_result.dart';
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

  Future<MatchRosterLoadResult> loadRosterFromTeam({
    required String matchId,
    required String teamId,
    required bool replaceExisting,
  }) async {
    final teamPlayersResponse = await _supabase
        .from('team_players')
        .select('player_id, players(primary_position)')
        .eq('team_id', teamId)
        .eq('is_active', true);

    final teamPlayers = teamPlayersResponse as List;
    if (teamPlayers.isEmpty) {
      return const MatchRosterLoadResult(
        addedCount: 0,
        skippedCount: 0,
        removedCount: 0,
      );
    }

    final existingResponse = await _supabase
        .from('match_players')
        .select('id, player_id')
        .eq('match_id', matchId)
        .eq('team_id', teamId);

    final existingRows = existingResponse as List;
    final existingPlayerIds = existingRows
        .map((item) => item['player_id'] as String)
        .toSet();

    var removedCount = 0;
    if (replaceExisting && existingRows.isNotEmpty) {
      await _supabase
          .from('match_players')
          .delete()
          .eq('match_id', matchId)
          .eq('team_id', teamId);

      removedCount = existingRows.length;
      existingPlayerIds.clear();
    }

    final rowsToInsert = <Map<String, dynamic>>[];
    var skippedCount = 0;

    for (final item in teamPlayers) {
      final playerId = item['player_id'] as String?;
      if (playerId == null) {
        skippedCount++;
        continue;
      }

      if (existingPlayerIds.contains(playerId)) {
        skippedCount++;
        continue;
      }

      final playerRelation = item['players'];
      String position = 'nao_informado';

      if (playerRelation is Map<String, dynamic>) {
        position = playerRelation['primary_position'] as String? ?? 'nao_informado';
      } else if (playerRelation is List && playerRelation.isNotEmpty) {
        final first = playerRelation.first;
        if (first is Map<String, dynamic>) {
          position = first['primary_position'] as String? ?? 'nao_informado';
        }
      }

      rowsToInsert.add({
        'match_id': matchId,
        'team_id': teamId,
        'player_id': playerId,
        'shirt_number': null,
        'is_goalkeeper': position == 'goleiro',
        'position_in_match': position,
        'is_active_in_match': true,
      });
    }

    if (rowsToInsert.isNotEmpty) {
      await _supabase.from('match_players').insert(rowsToInsert);
    }

    return MatchRosterLoadResult(
      addedCount: rowsToInsert.length,
      skippedCount: skippedCount,
      removedCount: removedCount,
    );
  }
}
