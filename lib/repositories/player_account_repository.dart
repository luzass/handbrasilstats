import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerAccountRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PlayerCompetitionLink>> getCurrentPlayerCompetitions() async {
    final response = await _supabase.rpc('get_current_player_competitions');

    return (response as List)
        .map(
          (item) => PlayerCompetitionLink.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<PlayerCompetitionStats>> getCurrentPlayerStats() async {
    final response = await _supabase.rpc('get_current_player_stats');

    return (response as List)
        .map(
          (item) => PlayerCompetitionStats.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}

class PlayerCompetitionLink {
  final String playerId;
  final String playerName;
  final String? photoUrl;
  final String? teamId;
  final String? teamName;
  final String? teamShortName;
  final String? competitionId;
  final String? competitionName;
  final int? year;
  final String? category;
  final String? gender;

  const PlayerCompetitionLink({
    required this.playerId,
    required this.playerName,
    required this.photoUrl,
    required this.teamId,
    required this.teamName,
    required this.teamShortName,
    required this.competitionId,
    required this.competitionName,
    required this.year,
    required this.category,
    required this.gender,
  });

  factory PlayerCompetitionLink.fromMap(Map<String, dynamic> map) {
    return PlayerCompetitionLink(
      playerId: map['player_id'] as String,
      playerName: map['player_name'] as String? ?? 'Jogador',
      photoUrl: map['photo_url'] as String?,
      teamId: map['team_id'] as String?,
      teamName: map['team_name'] as String?,
      teamShortName: map['team_short_name'] as String?,
      competitionId: map['competition_id'] as String?,
      competitionName: map['competition_name'] as String?,
      year: (map['year'] as num?)?.toInt(),
      category: map['category'] as String?,
      gender: map['gender'] as String?,
    );
  }
}

class PlayerCompetitionStats {
  final String playerId;
  final String playerName;
  final String? photoUrl;
  final String competitionId;
  final String competitionName;
  final String teamId;
  final String teamName;
  final String? teamShortName;
  final int matchesCount;
  final int shots;
  final int goals;
  final int savedShots;
  final int outs;
  final int posts;
  final int blocked;
  final double? shotPercentage;
  final int yellowCards;
  final int redCards;
  final int blueCards;
  final int twoMinutes;
  final int goalkeeperShotsFaced;
  final int goalkeeperSaves;
  final int goalkeeperGoalsConceded;
  final double? savePercentage;

  const PlayerCompetitionStats({
    required this.playerId,
    required this.playerName,
    required this.photoUrl,
    required this.competitionId,
    required this.competitionName,
    required this.teamId,
    required this.teamName,
    required this.teamShortName,
    required this.matchesCount,
    required this.shots,
    required this.goals,
    required this.savedShots,
    required this.outs,
    required this.posts,
    required this.blocked,
    required this.shotPercentage,
    required this.yellowCards,
    required this.redCards,
    required this.blueCards,
    required this.twoMinutes,
    required this.goalkeeperShotsFaced,
    required this.goalkeeperSaves,
    required this.goalkeeperGoalsConceded,
    required this.savePercentage,
  });

  factory PlayerCompetitionStats.fromMap(Map<String, dynamic> map) {
    return PlayerCompetitionStats(
      playerId: map['player_id'] as String,
      playerName: map['player_name'] as String? ?? 'Jogador',
      photoUrl: map['photo_url'] as String?,
      competitionId: map['competition_id'] as String,
      competitionName: map['competition_name'] as String? ?? 'Competição',
      teamId: map['team_id'] as String,
      teamName: map['team_name'] as String? ?? 'Time',
      teamShortName: map['team_short_name'] as String?,
      matchesCount: (map['matches_count'] as num?)?.toInt() ?? 0,
      shots: (map['shots'] as num?)?.toInt() ?? 0,
      goals: (map['goals'] as num?)?.toInt() ?? 0,
      savedShots: (map['saved_shots'] as num?)?.toInt() ?? 0,
      outs: (map['outs'] as num?)?.toInt() ?? 0,
      posts: (map['posts'] as num?)?.toInt() ?? 0,
      blocked: (map['blocked'] as num?)?.toInt() ?? 0,
      shotPercentage: (map['shot_percentage'] as num?)?.toDouble(),
      yellowCards: (map['yellow_cards'] as num?)?.toInt() ?? 0,
      redCards: (map['red_cards'] as num?)?.toInt() ?? 0,
      blueCards: (map['blue_cards'] as num?)?.toInt() ?? 0,
      twoMinutes: (map['two_minutes'] as num?)?.toInt() ?? 0,
      goalkeeperShotsFaced:
          (map['goalkeeper_shots_faced'] as num?)?.toInt() ?? 0,
      goalkeeperSaves: (map['goalkeeper_saves'] as num?)?.toInt() ?? 0,
      goalkeeperGoalsConceded:
          (map['goalkeeper_goals_conceded'] as num?)?.toInt() ?? 0,
      savePercentage: (map['save_percentage'] as num?)?.toDouble(),
    );
  }
}
