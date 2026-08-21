import 'package:supabase_flutter/supabase_flutter.dart';

class StandaloneScoutRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String normalizeTeamName(String name) {
    final lowered = name.trim().toLowerCase();
    const from = 'áàãâäéèêëíìîïóòõôöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';

    final buffer = StringBuffer();
    for (final rune in lowered.runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to.substring(index, index + 1) : char);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<Map<String, dynamic>> getOrCreateTeam(String name) async {
    final cleanName = name.trim();
    final nameKey = normalizeTeamName(cleanName);
    final userId = _supabase.auth.currentUser?.id;

    final existing = await _supabase
        .from('standalone_teams')
        .select()
        .eq('name_key', nameKey)
        .maybeSingle();

    if (existing != null) {
      return Map<String, dynamic>.from(existing);
    }

    final created = await _supabase
        .from('standalone_teams')
        .insert({
          'name': cleanName,
          'name_key': nameKey,
          'created_by': userId,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(created);
  }

  Future<Map<String, dynamic>> createMatch({
    required String homeTeamId,
    required String awayTeamId,
    required String homeTeamName,
    required String awayTeamName,
  }) async {
    final created = await _supabase
        .from('standalone_matches')
        .insert({
          'home_standalone_team_id': homeTeamId,
          'away_standalone_team_id': awayTeamId,
          'home_team_name': homeTeamName,
          'away_team_name': awayTeamName,
          'created_by': _supabase.auth.currentUser?.id,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(created);
  }

  Future<Map<String, dynamic>> createEvent({
    required String matchId,
    required String teamId,
    required String opponentTeamId,
    required String eventKind,
    required String eventType,
    required String period,
    required int minute,
    required int second,
    required int sequenceOrder,
    required int homeScoreAfter,
    required int awayScoreAfter,
    String? playerNumber,
    String? goalkeeperNumber,
    int? shotZoneId,
    int? goalZoneId,
  }) async {
    final created = await _supabase
        .from('standalone_events')
        .insert({
          'standalone_match_id': matchId,
          'standalone_team_id': teamId,
          'opponent_standalone_team_id': opponentTeamId,
          'event_kind': eventKind,
          'event_type': eventType,
          'player_number': playerNumber,
          'goalkeeper_number': goalkeeperNumber,
          'shot_zone_id': shotZoneId,
          'goal_zone_id': goalZoneId,
          'period': period,
          'minute': minute,
          'second': second,
          'sequence_order': sequenceOrder,
          'home_score_after': homeScoreAfter,
          'away_score_after': awayScoreAfter,
          'created_by': _supabase.auth.currentUser?.id,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(created);
  }

  Future<void> updateMatchScore({
    required String matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    await _supabase.from('standalone_matches').update({
      'home_score': homeScore,
      'away_score': awayScore,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('standalone_events').delete().eq('id', eventId);
  }
}
