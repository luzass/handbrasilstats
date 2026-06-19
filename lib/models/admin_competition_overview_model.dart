class CompetitionTeamOverview {
  final String id;
  final String name;
  final String? state;
  final String? shieldUrl;

  const CompetitionTeamOverview({
    required this.id,
    required this.name,
    required this.state,
    required this.shieldUrl,
  });
}

class CompetitionMatchOverview {
  final String id;
  final CompetitionTeamOverview homeTeam;
  final CompetitionTeamOverview awayTeam;
  final String? matchDatetime;
  final String? venueName;
  final String? venueCity;
  final String? venueState;
  final String status;
  final int scoreHome;
  final int scoreAway;

  const CompetitionMatchOverview({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchDatetime,
    required this.venueName,
    required this.venueCity,
    required this.venueState,
    required this.status,
    required this.scoreHome,
    required this.scoreAway,
  });
}

class CompetitionStandingsRow {
  final int position;
  final CompetitionTeamOverview team;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const CompetitionStandingsRow({
    required this.position,
    required this.team,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });
}

class CompetitionTopScorerRow {
  final CompetitionTeamOverview team;
  final String playerName;
  final int goals;

  const CompetitionTopScorerRow({
    required this.team,
    required this.playerName,
    required this.goals,
  });
}

class CompetitionGoalkeeperRow {
  final CompetitionTeamOverview team;
  final String goalkeeperName;
  final int saves;
  final int shotsFaced;
  final int goalsConceded;
  final double savePercentage;

  const CompetitionGoalkeeperRow({
    required this.team,
    required this.goalkeeperName,
    required this.saves,
    required this.shotsFaced,
    required this.goalsConceded,
    required this.savePercentage,
  });
}

class CompetitionOverviewDetails {
  final List<CompetitionTeamOverview> teams;
  final List<CompetitionMatchOverview> matches;
  final List<CompetitionStandingsRow> standings;
  final List<CompetitionTopScorerRow> topScorers;
  final List<CompetitionGoalkeeperRow> topGoalkeepers;

  const CompetitionOverviewDetails({
    required this.teams,
    required this.matches,
    required this.standings,
    required this.topScorers,
    required this.topGoalkeepers,
  });
}
