import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/competition_model.dart';
import '../models/viewer_match_model.dart';

class ViewerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _visibleCompetitionNames = [
    'Campeonato W.A Masculino',
    'Campeonato W.A Feminino',
  ];

  Future<List<CompetitionModel>> getFeaturedCompetitions() async {
    final response = await _supabase
        .from('competitions')
        .select()
        .eq('is_featured_for_viewer', true)
        .inFilter('name', _visibleCompetitionNames)
        .order('year', ascending: false)
        .order('name', ascending: true);

    return (response as List)
        .map((item) => CompetitionModel.fromMap(item))
        .toList();
  }

  Future<List<ViewerMatchModel>> getCompetitionMatches(String competitionId) async {
    final response = await _supabase
        .from('matches')
        .select('''
          id,
          competition_id,
          home_team_id,
          away_team_id,
          score_home,
          score_away,
          status,
          scout_status,
          match_stage,
          match_datetime,
          current_period,
          current_minute,
          current_second,
          competitions(name),
          home_team:teams!matches_home_team_id_fkey(name, shield_url),
          away_team:teams!matches_away_team_id_fkey(name, shield_url)
        ''')
        .eq('competition_id', competitionId)
        .order('match_datetime', ascending: true);

    return (response as List)
        .map((item) => ViewerMatchModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<ViewerMatchModel?> getMatchById(String matchId) async {
    final response = await _supabase
        .from('matches')
        .select('''
          id,
          competition_id,
          home_team_id,
          away_team_id,
          score_home,
          score_away,
          status,
          scout_status,
          match_stage,
          match_datetime,
          current_period,
          current_minute,
          current_second,
          competitions(name),
          home_team:teams!matches_home_team_id_fkey(name, shield_url),
          away_team:teams!matches_away_team_id_fkey(name, shield_url)
        ''')
        .eq('id', matchId)
        .maybeSingle();

    if (response == null) return null;
    return ViewerMatchModel.fromMap(Map<String, dynamic>.from(response));
  }
}
