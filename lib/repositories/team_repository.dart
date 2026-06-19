import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team_model.dart';

class TeamRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TeamModel>> getTeams() async {
    final response = await _supabase
        .from('teams')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((item) => TeamModel.fromMap(item))
        .toList();
  }

  Future<TeamModel> createTeam(TeamModel team) async {
    final response = await _supabase
        .from('teams')
        .insert(team.toInsertMap())
        .select()
        .single();

    return TeamModel.fromMap(response);
  }

  Future<TeamModel> updateTeam(TeamModel team) async {
    final response = await _supabase
        .from('teams')
        .update(team.toUpdateMap())
        .eq('id', team.id)
        .select()
        .single();

    return TeamModel.fromMap(response);
  }
}