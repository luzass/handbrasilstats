import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_model.dart';

class MatchRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MatchModel>> getMatches() async {
    final response = await _supabase
        .from('matches')
        .select()
        .order('match_datetime', ascending: false);

    return (response as List)
        .map((item) => MatchModel.fromMap(item))
        .toList();
  }

  Future<void> createMatch(MatchModel match) async {
    await _supabase.from('matches').insert(match.toInsertMap());
  }

  Future<void> updateMatch(MatchModel match) async {
    await _supabase
        .from('matches')
        .update(match.toUpdateMap())
        .eq('id', match.id);
  }
}