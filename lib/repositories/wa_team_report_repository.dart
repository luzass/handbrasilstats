import 'package:supabase_flutter/supabase_flutter.dart';

class WaTeamReportRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCompetitions() async {
    final response = await _supabase
        .from('competitions')
        .select('id, name, gender, year');

    final competitions =
        (response as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .where((item) {
              final name = (item['name'] as String? ?? '').toLowerCase();
              final compactName = name.replaceAll(RegExp('[^a-z0-9]'), '');
              return compactName.contains('wa') || name.contains('interatl');
            })
            .toList()
          ..sort((a, b) {
            final genderCompare = _gender(a).compareTo(_gender(b));
            if (genderCompare != 0) return genderCompare;
            return ((b['year'] as num?)?.toInt() ?? 0).compareTo(
              (a['year'] as num?)?.toInt() ?? 0,
            );
          });

    return competitions;
  }

  Future<Map<String, dynamic>> getCompetitionReport({
    required Map<String, dynamic> competition,
  }) async {
    final competitionId = competition['id'] as String;
    final matchResponse = await _supabase
        .from('matches')
        .select('''
          id,
          home_team_id,
          away_team_id,
          score_home,
          score_away,
          status,
          match_stage,
          match_datetime,
          home_team:teams!matches_home_team_id_fkey(id, name, short_name, shield_url),
          away_team:teams!matches_away_team_id_fkey(id, name, short_name, shield_url)
        ''')
        .eq('competition_id', competitionId)
        .order('match_datetime');

    final matches = (matchResponse as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final teams = <String, Map<String, dynamic>>{};

    for (final match in matches) {
      for (final side in ['home_team', 'away_team']) {
        final rawTeam = match[side];
        if (rawTeam is Map) {
          final team = Map<String, dynamic>.from(rawTeam);
          final id = team['id'] as String?;
          if (id != null) teams[id] = team;
        }
      }
    }

    if (matches.isEmpty) {
      return {
        'competition': competition,
        'teams': <String, Map<String, dynamic>>{},
        'matches': matches,
        'team_stats': <String, Map<String, dynamic>>{},
        'players': <String, Map<String, dynamic>>{},
        'goalkeepers': <String, Map<String, dynamic>>{},
        'shots': <String, List<Map<String, dynamic>>>{},
      };
    }

    final matchIds = matches.map((match) => match['id'] as String).toList();
    final responses = await Future.wait([
      _supabase
          .from('v_match_live_stats')
          .select()
          .inFilter('match_id', matchIds),
      _supabase
          .from('v_match_player_stats')
          .select()
          .inFilter('match_id', matchIds),
      _supabase
          .from('v_match_goalkeeper_stats')
          .select()
          .inFilter('match_id', matchIds),
      _supabase
          .from('shot_events')
          .select(
            'match_id, team_id, player_id, goalkeeper_player_id, zone_id, goal_zone_id, shot_type, shot_result',
          )
          .inFilter('match_id', matchIds),
    ]);

    final teamStats = <String, Map<String, dynamic>>{};
    for (final raw in responses[0] as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final teamId = row['team_id'] as String?;
      if (teamId != null) _addStats(teamStats, teamId, row);
    }

    final players = <String, Map<String, dynamic>>{};
    for (final raw in responses[1] as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final playerId = row['player_id'] as String?;
      final teamId = row['team_id'] as String?;
      if (playerId == null || teamId == null) continue;
      final key = '$teamId::$playerId';
      _addStats(players, key, row, nameKey: 'player_name');
    }

    final goalkeepers = <String, Map<String, dynamic>>{};
    for (final raw in responses[2] as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final playerId = row['player_id'] as String?;
      final teamId = row['team_id'] as String?;
      if (playerId == null || teamId == null) continue;
      final key = '$teamId::$playerId';
      _addStats(goalkeepers, key, row, nameKey: 'goalkeeper_name');
    }

    final shots = <String, List<Map<String, dynamic>>>{};
    for (final raw in responses[3] as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final teamId = row['team_id'] as String?;
      if (teamId != null) shots.putIfAbsent(teamId, () => []).add(row);
    }

    for (final stats in teamStats.values) {
      _recalculatePercentages(stats, isGoalkeeper: false);
    }
    for (final stats in players.values) {
      _recalculatePercentages(stats, isGoalkeeper: false);
    }
    for (final stats in goalkeepers.values) {
      _recalculatePercentages(stats, isGoalkeeper: true);
    }

    return {
      'competition': competition,
      'teams': teams,
      'matches': matches,
      'team_stats': teamStats,
      'players': players,
      'goalkeepers': goalkeepers,
      'shots': shots,
    };
  }

  static String _gender(Map<String, dynamic> competition) {
    final gender = (competition['gender'] as String? ?? '').toLowerCase();
    final name = (competition['name'] as String? ?? '').toLowerCase();
    if (gender.contains('fem') || name.contains('femin')) return 'feminino';
    if (gender.contains('masc') || name.contains('mascul')) return 'masculino';
    return gender;
  }

  static void _addStats(
    Map<String, Map<String, dynamic>> aggregate,
    String key,
    Map<String, dynamic> row, {
    String? nameKey,
  }) {
    final current = aggregate.putIfAbsent(
      key,
      () => {
        if (nameKey != null) nameKey: row[nameKey],
        if (row['player_id'] != null) 'player_id': row['player_id'],
        if (row['player_number'] != null) 'player_number': row['player_number'],
        'team_id': row['team_id'],
        '_values': <String, num>{},
      },
    );
    final values = current['_values'] as Map<String, num>;
    for (final entry in row.entries) {
      final value = entry.value;
      if (value is num && entry.key != 'player_number') {
        values[entry.key] = (values[entry.key] ?? 0) + value;
      }
    }
    current.addAll(values);
  }

  static void _recalculatePercentages(
    Map<String, dynamic> stats, {
    required bool isGoalkeeper,
  }) {
    void setPercent(String name, String numerator, String denominator) {
      final total = stats[denominator] as num? ?? 0;
      final success = stats[numerator] as num? ?? 0;
      stats[name] = total == 0 ? 0 : success / total * 100;
    }

    if (isGoalkeeper) {
      setPercent('save_percentage', 'saves', 'shots_faced');
      setPercent('save_percentage_7m', 'saves_7m', 'shots_faced_7m');
      setPercent('save_percentage_9m', 'saves_9m', 'shots_faced_9m');
      return;
    }

    final goalsKey = stats.containsKey('goals_scored')
        ? 'goals_scored'
        : 'goals';
    setPercent('shot_percentage', goalsKey, 'shots');
    setPercent('shot_percentage_7m', 'goals_7m', 'shots_7m');
    setPercent('shot_percentage_9m', 'goals_9m', 'shots_9m');
    setPercent('shot_percentage_6m', 'goals_6m', 'shots_6m');
  }
}
