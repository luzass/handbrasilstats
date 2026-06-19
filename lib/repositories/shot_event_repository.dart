import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shot_event_model.dart';

class ShotEventRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createShotEvent(ShotEventModel event) async {
    await _supabase.from('shot_events').insert(event.toInsertMap());
  }

  Future<void> updateShotEvent(
    String eventId,
    Map<String, dynamic> data,
  ) async {
    await _supabase.from('shot_events').update(data).eq('id', eventId);
  }

  Future<int> getNextSequenceOrder(String matchId) async {
    final response = await _supabase
        .from('shot_events')
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

  Future<List<Map<String, dynamic>>> getMatchEvents(String matchId) async {
    final response = await _supabase
        .from('shot_events')
        .select()
        .eq('match_id', matchId)
        .order('sequence_order', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteShotEvent(String eventId) async {
    await _supabase.from('shot_events').delete().eq('id', eventId);
  }
}