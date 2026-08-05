import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_competition_overview_model.dart';
import '../models/competition_model.dart';

class AdminCompetitionOverviewRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CompetitionModel>> getCompetitionsOrderedByDate() async {
    final response = await _supabase
        .from('competitions')
        .select()
        .order('start_date', ascending: false)
        .order('year', ascending: false)
        .order('name', ascending: true);

    final items = (response as List)
        .map((item) => CompetitionModel.fromMap(item))
        .toList();

    items.sort(_sortCompetitions);
    return items;
  }

  Future<CompetitionOverviewDetails> getCompetitionDetails(
    CompetitionModel competition,
  ) async {
    final matchesResponse = await _supabase
        .from('matches')
        .select('''
          id,
          competition_id,
          home_team_id,
          away_team_id,
          match_datetime,
          venue_name,
          venue_city,
          venue_state,
          match_stage,
          status,
          score_home,
          score_away,
          home_team:teams!matches_home_team_id_fkey(id, name, short_name, state, shield_url),
          away_team:teams!matches_away_team_id_fkey(id, name, short_name, state, shield_url)
        ''')
        .eq('competition_id', competition.id)
        .order('match_datetime', ascending: false);

    final teamMap = <String, CompetitionTeamOverview>{};
    final matches = <CompetitionMatchOverview>[];

    for (final rawItem in (matchesResponse as List)) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      final homeTeam = _teamFromMap(
        item['home_team'] as Map?,
        fallbackId: item['home_team_id'] as String?,
      );
      final awayTeam = _teamFromMap(
        item['away_team'] as Map?,
        fallbackId: item['away_team_id'] as String?,
      );

      teamMap[homeTeam.id] = homeTeam;
      teamMap[awayTeam.id] = awayTeam;

      matches.add(
        CompetitionMatchOverview(
          id: item['id'] as String,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          matchDatetime: item['match_datetime']?.toString(),
          venueName: item['venue_name'] as String?,
          venueCity: item['venue_city'] as String?,
          venueState: item['venue_state'] as String?,
          matchStage: item['match_stage'] as String? ?? 'classificatoria',
          status: item['status'] as String? ?? 'agendado',
          scoreHome: item['score_home'] as int? ?? 0,
          scoreAway: item['score_away'] as int? ?? 0,
        ),
      );
    }

    final teams = teamMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (matches.isEmpty) {
      return const CompetitionOverviewDetails(
        teams: [],
        matches: [],
        standings: [],
        topScorers: [],
        topGoalkeepers: [],
      );
    }

    final matchIds = matches.map((item) => item.id).toList();

    final results = await Future.wait([
      _supabase
          .from('v_match_player_stats')
          .select()
          .inFilter('match_id', matchIds),
      _supabase
          .from('v_match_goalkeeper_stats')
          .select()
          .inFilter('match_id', matchIds),
    ]);

    final playerStats = (results[0] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final goalkeeperStats = (results[1] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return CompetitionOverviewDetails(
      teams: teams,
      matches: matches,
      standings: _buildStandings(teams: teams, matches: matches),
      topScorers: _buildTopScorers(teams: teamMap, rows: playerStats),
      topGoalkeepers: _buildTopGoalkeepers(teams: teamMap, rows: goalkeeperStats),
    );
  }

  int _sortCompetitions(CompetitionModel a, CompetitionModel b) {
    final aDate = _competitionSortDate(a);
    final bDate = _competitionSortDate(b);
    final dateCompare = bDate.compareTo(aDate);
    if (dateCompare != 0) return dateCompare;
    return a.name.compareTo(b.name);
  }

  DateTime _competitionSortDate(CompetitionModel item) {
    final parsedStart = DateTime.tryParse(item.startDate ?? '');
    if (parsedStart != null) return parsedStart;

    final parsedEnd = DateTime.tryParse(item.endDate ?? '');
    if (parsedEnd != null) return parsedEnd;

    return DateTime(item.year, 1, 1);
  }

  CompetitionTeamOverview _teamFromMap(
    Map? raw, {
    String? fallbackId,
  }) {
    final map = Map<String, dynamic>.from(raw ?? const {});
    return CompetitionTeamOverview(
      id: map['id'] as String? ?? fallbackId ?? '',
      name: map['name'] as String? ?? 'Time',
      shortName: map['short_name'] as String?,
      state: map['state'] as String?,
      shieldUrl: map['shield_url'] as String?,
    );
  }

  List<CompetitionStandingsRow> _buildStandings({
    required List<CompetitionTeamOverview> teams,
    required List<CompetitionMatchOverview> matches,
  }) {
    final table = <String, _StandingsAccumulator>{};

    for (final team in teams) {
      table[team.id] = _StandingsAccumulator(team: team);
    }

    for (final match in matches.where(
      (item) =>
          item.status == 'finalizado' &&
          item.matchStage == 'classificatoria',
    )) {
      final home = table.putIfAbsent(
        match.homeTeam.id,
        () => _StandingsAccumulator(team: match.homeTeam),
      );
      final away = table.putIfAbsent(
        match.awayTeam.id,
        () => _StandingsAccumulator(team: match.awayTeam),
      );

      home.played += 1;
      away.played += 1;
      home.goalsFor += match.scoreHome;
      home.goalsAgainst += match.scoreAway;
      away.goalsFor += match.scoreAway;
      away.goalsAgainst += match.scoreHome;

      if (match.scoreHome > match.scoreAway) {
        home.wins += 1;
        away.losses += 1;
      } else if (match.scoreHome < match.scoreAway) {
        away.wins += 1;
        home.losses += 1;
      } else {
        home.draws += 1;
        away.draws += 1;
      }
    }

    final finishedClassificationMatches = matches
        .where(
          (item) =>
              item.status == 'finalizado' &&
              item.matchStage == 'classificatoria',
        )
        .toList();

    final items = _sortStandings(
      table.values.toList(),
      finishedClassificationMatches,
    );

    return [
      for (var i = 0; i < items.length; i++)
        CompetitionStandingsRow(
          position: i + 1,
          team: items[i].team,
          played: items[i].played,
          wins: items[i].wins,
          draws: items[i].draws,
          losses: items[i].losses,
          goalsFor: items[i].goalsFor,
          goalsAgainst: items[i].goalsAgainst,
          goalDifference: items[i].goalDifference,
          points: items[i].points,
        ),
    ];
  }

  List<_StandingsAccumulator> _sortStandings(
    List<_StandingsAccumulator> items,
    List<CompetitionMatchOverview> matches,
  ) {
    final sorted = items.toList()
      ..sort((a, b) {
        final pointsCompare = b.points.compareTo(a.points);
        if (pointsCompare != 0) return pointsCompare;
        return _compareGeneralCriteria(a, b);
      });

    final result = <_StandingsAccumulator>[];
    var index = 0;

    while (index < sorted.length) {
      final points = sorted[index].points;
      final group = <_StandingsAccumulator>[];

      while (index < sorted.length && sorted[index].points == points) {
        group.add(sorted[index]);
        index += 1;
      }

      if (group.length == 1) {
        result.add(group.first);
        continue;
      }

      group.sort((a, b) => _compareTiedTeams(a, b, group, matches));
      result.addAll(group);
    }

    return result;
  }

  int _compareTiedTeams(
    _StandingsAccumulator a,
    _StandingsAccumulator b,
    List<_StandingsAccumulator> tiedGroup,
    List<CompetitionMatchOverview> matches,
  ) {
    if (tiedGroup.length == 2) {
      final direct = _headToHeadForTwo(a.team.id, b.team.id, matches);
      if (direct != 0) return direct;
      return _compareGeneralCriteria(a, b);
    }

    final tiedIds = tiedGroup.map((item) => item.team.id).toSet();
    final aMini = _miniTableFor(a.team.id, tiedIds, matches);
    final bMini = _miniTableFor(b.team.id, tiedIds, matches);

    final averageCompare = bMini.goalAverage.compareTo(aMini.goalAverage);
    if (averageCompare != 0) return averageCompare;

    final goalsForCompare = bMini.goalsFor.compareTo(aMini.goalsFor);
    if (goalsForCompare != 0) return goalsForCompare;

    final goalsAgainstCompare = aMini.goalsAgainst.compareTo(bMini.goalsAgainst);
    if (goalsAgainstCompare != 0) return goalsAgainstCompare;

    return _compareGeneralCriteria(a, b);
  }

  int _headToHeadForTwo(
    String teamAId,
    String teamBId,
    List<CompetitionMatchOverview> matches,
  ) {
    var teamAPoints = 0;
    var teamBPoints = 0;

    for (final match in matches.where(
      (item) =>
          (item.homeTeam.id == teamAId && item.awayTeam.id == teamBId) ||
          (item.homeTeam.id == teamBId && item.awayTeam.id == teamAId),
    )) {
      final teamAGoals =
          match.homeTeam.id == teamAId ? match.scoreHome : match.scoreAway;
      final teamBGoals =
          match.homeTeam.id == teamBId ? match.scoreHome : match.scoreAway;

      if (teamAGoals > teamBGoals) {
        teamAPoints += 2;
      } else if (teamBGoals > teamAGoals) {
        teamBPoints += 2;
      } else {
        teamAPoints += 1;
        teamBPoints += 1;
      }
    }

    return teamBPoints.compareTo(teamAPoints);
  }

  _MiniTableAccumulator _miniTableFor(
    String teamId,
    Set<String> tiedIds,
    List<CompetitionMatchOverview> matches,
  ) {
    final accumulator = _MiniTableAccumulator();

    for (final match in matches.where(
      (item) =>
          tiedIds.contains(item.homeTeam.id) &&
          tiedIds.contains(item.awayTeam.id),
    )) {
      if (match.homeTeam.id == teamId) {
        accumulator.goalsFor += match.scoreHome;
        accumulator.goalsAgainst += match.scoreAway;
      } else if (match.awayTeam.id == teamId) {
        accumulator.goalsFor += match.scoreAway;
        accumulator.goalsAgainst += match.scoreHome;
      }
    }

    return accumulator;
  }

  int _compareGeneralCriteria(
    _StandingsAccumulator a,
    _StandingsAccumulator b,
  ) {
    final diffCompare = b.goalDifference.compareTo(a.goalDifference);
    if (diffCompare != 0) return diffCompare;

    final goalsForCompare = b.goalsFor.compareTo(a.goalsFor);
    if (goalsForCompare != 0) return goalsForCompare;

    final goalsAgainstCompare = a.goalsAgainst.compareTo(b.goalsAgainst);
    if (goalsAgainstCompare != 0) return goalsAgainstCompare;

    return a.team.displayName.compareTo(b.team.displayName);
  }

  List<CompetitionTopScorerRow> _buildTopScorers({
    required Map<String, CompetitionTeamOverview> teams,
    required List<Map<String, dynamic>> rows,
  }) {
    final grouped = <String, _ScorerAccumulator>{};

    for (final row in rows) {
      final playerId = row['player_id'] as String?;
      final teamId = row['team_id'] as String?;
      if (playerId == null || teamId == null) continue;

      final key = '$teamId::$playerId';
      final current = grouped.putIfAbsent(
        key,
        () => _ScorerAccumulator(
          teamId: teamId,
          playerName: row['player_name'] as String? ?? 'Jogador',
        ),
      );
      current.goals += (row['goals'] as num?)?.toInt() ?? 0;
    }

    final items = grouped.values.toList()
      ..removeWhere((item) => item.goals <= 0)
      ..sort((a, b) {
        final goalsCompare = b.goals.compareTo(a.goals);
        if (goalsCompare != 0) return goalsCompare;
        return a.playerName.compareTo(b.playerName);
      });

    return items.take(10).map((item) {
      final team = teams[item.teamId] ??
          const CompetitionTeamOverview(
            id: '',
            name: 'Time',
            shortName: null,
            state: null,
            shieldUrl: null,
          );

      return CompetitionTopScorerRow(
        team: team,
        playerName: item.playerName,
        goals: item.goals,
      );
    }).toList();
  }

  List<CompetitionGoalkeeperRow> _buildTopGoalkeepers({
    required Map<String, CompetitionTeamOverview> teams,
    required List<Map<String, dynamic>> rows,
  }) {
    final grouped = <String, _GoalkeeperAccumulator>{};

    for (final row in rows) {
      final playerId = row['player_id'] as String?;
      final teamId = row['team_id'] as String?;
      if (playerId == null || teamId == null) continue;

      final key = '$teamId::$playerId';
      final current = grouped.putIfAbsent(
        key,
        () => _GoalkeeperAccumulator(
          teamId: teamId,
          goalkeeperName: row['goalkeeper_name'] as String? ?? 'Goleiro',
        ),
      );
      current.saves += (row['saves'] as num?)?.toInt() ?? 0;
      current.shotsFaced += (row['shots_faced'] as num?)?.toInt() ?? 0;
      current.goalsConceded += (row['goals_conceded'] as num?)?.toInt() ?? 0;
    }

    final items = grouped.values
        .where((item) => item.shotsFaced > 0)
        .toList()
      ..sort((a, b) {
        final pctCompare = b.savePercentage.compareTo(a.savePercentage);
        if (pctCompare != 0) return pctCompare;

        final savesCompare = b.saves.compareTo(a.saves);
        if (savesCompare != 0) return savesCompare;

        return a.goalkeeperName.compareTo(b.goalkeeperName);
      });

    return items.take(10).map((item) {
      final team = teams[item.teamId] ??
          const CompetitionTeamOverview(
            id: '',
            name: 'Time',
            shortName: null,
            state: null,
            shieldUrl: null,
          );

      return CompetitionGoalkeeperRow(
        team: team,
        goalkeeperName: item.goalkeeperName,
        saves: item.saves,
        shotsFaced: item.shotsFaced,
        goalsConceded: item.goalsConceded,
        savePercentage: item.savePercentage,
      );
    }).toList();
  }
}

class _StandingsAccumulator {
  final CompetitionTeamOverview team;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  _StandingsAccumulator({
    required this.team,
  });

  int get goalDifference => goalsFor - goalsAgainst;
  int get points => (wins * 2) + draws;
}

class _MiniTableAccumulator {
  int goalsFor = 0;
  int goalsAgainst = 0;

  double get goalAverage {
    if (goalsAgainst == 0) {
      return goalsFor == 0 ? 0 : goalsFor.toDouble();
    }
    return goalsFor / goalsAgainst;
  }
}

class _ScorerAccumulator {
  final String teamId;
  final String playerName;
  int goals = 0;

  _ScorerAccumulator({
    required this.teamId,
    required this.playerName,
  });
}

class _GoalkeeperAccumulator {
  final String teamId;
  final String goalkeeperName;
  int saves = 0;
  int shotsFaced = 0;
  int goalsConceded = 0;

  _GoalkeeperAccumulator({
    required this.teamId,
    required this.goalkeeperName,
  });

  double get savePercentage {
    if (shotsFaced == 0) return 0;
    return (saves / shotsFaced) * 100;
  }
}
