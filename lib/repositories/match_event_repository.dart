import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_event_model.dart';

class MatchEventRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createMatchEvent(MatchEventModel event) async {
    await _supabase.from('match_events').insert(event.toInsertMap());
  }

  Future<void> updateMatchEvent(MatchEventModel event) async {
    await _supabase
        .from('match_events')
        .update(event.toUpdateMap())
        .eq('id', event.id);
  }

  Future<void> deleteMatchEvent(String eventId) async {
    await _supabase.from('match_events').delete().eq('id', eventId);
  }

  Future<List<Map<String, dynamic>>> getMatchEvents(String matchId) async {
    final response = await _supabase
        .from('match_events')
        .select()
        .eq('match_id', matchId)
        .order('sequence_order', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> getNextSequenceOrder(String matchId) async {
    final response = await _supabase
        .from('match_events')
        .select('sequence_order')
        .eq('match_id', matchId)
        .order('sequence_order', ascending: false)
        .limit(1);

    if ((response as List).isEmpty) {
      return 1;
    }

    final last = response.first['sequence_order'] as int? ?? 0;
    return last + 1;
  }
}