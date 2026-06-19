import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/competition_model.dart';

class CompetitionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CompetitionModel>> getCompetitions() async {
    final response = await _supabase
        .from('competitions')
        .select()
        .order('year', ascending: false)
        .order('name', ascending: true);

    return (response as List)
        .map((item) => CompetitionModel.fromMap(item))
        .toList();
  }

  Future<void> createCompetition(CompetitionModel competition) async {
    await _supabase.from('competitions').insert(competition.toInsertMap());
  }

  Future<void> updateCompetition(CompetitionModel competition) async {
    await _supabase
        .from('competitions')
        .update(competition.toUpdateMap())
        .eq('id', competition.id);
  }
}