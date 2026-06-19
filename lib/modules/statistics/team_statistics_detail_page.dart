import 'package:flutter/material.dart';

import '../../models/match_goal_zone_breakdown_model.dart';
import '../../models/player_model.dart';
import '../../repositories/player_repository.dart';
import '../../repositories/team_statistics_repository.dart';
import '../../widgets/athlete_photo_avatar.dart';
import '../../widgets/goal_zone_heatmap_widget.dart';
import '../../widgets/team_athlete_details_dialog.dart';

class TeamStatisticsDetailPage extends StatefulWidget {
  final String teamId;
  final String teamName;
  final String? shieldUrl;

  const TeamStatisticsDetailPage({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.shieldUrl,
  });

  @override
  State<TeamStatisticsDetailPage> createState() =>
      _TeamStatisticsDetailPageState();
}

class _TeamStatisticsDetailPageState extends State<TeamStatisticsDetailPage> {
  final _repository = TeamStatisticsRepository();
  final _playerRepository = PlayerRepository();

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _generalStats;
  List<MatchGoalZoneBreakdownModel> _teamGoalBreakdown = [];
  List<MatchGoalZoneBreakdownModel> _goalkeeperGoalBreakdown = [];
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _goalkeepers = [];
  List<Map<String, dynamic>> _teamShotEvents = [];
  Map<String, String?> _playerPhotoUrls = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _repository.getTeamGeneralStats(widget.teamId),
        _repository.getTeamGoalBreakdown(teamId: widget.teamId),
        _repository.getTeamGoalkeeperBreakdown(teamId: widget.teamId),
        _repository.getTeamPlayers(widget.teamId),
        _repository.getTeamGoalkeepers(widget.teamId),
        _repository.getTeamShotEvents(widget.teamId),
        _playerRepository.getPlayers(),
      ]);

      final allPlayers = results[6] as List<PlayerModel>;
      final photoMap = <String, String?>{};
      for (final player in allPlayers) {
        photoMap[player.id] = player.photoUrl;
      }

      if (!mounted) return;

      setState(() {
        _generalStats = results[0] as Map<String, dynamic>?;
        _teamGoalBreakdown = results[1] as List<MatchGoalZoneBreakdownModel>;
        _goalkeeperGoalBreakdown =
            results[2] as List<MatchGoalZoneBreakdownModel>;
        _players = results[3] as List<Map<String, dynamic>>;
        _goalkeepers = results[4] as List<Map<String, dynamic>>;
        _teamShotEvents = results[5] as List<Map<String, dynamic>>;
        _playerPhotoUrls = photoMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar estatísticas do time: $e';
        _isLoading = false;
      });
    }
  }

  String _fmt(dynamic value) => '${value ?? 0}';

  String _fmtNum(dynamic value) {
    if (value == null) return '0';
    if (value is num) return value.toStringAsFixed(2);
    return value.toString();
  }

  int _countShotsByResult(String result) {
    return _teamShotEvents.where((item) => item['shot_result'] == result).length;
  }

  Widget _buildShield(String? url, {double size = 60}) {
    if (url == null || url.isEmpty) {
      return Icon(Icons.shield_outlined, size: size);
    }

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Icon(Icons.shield_outlined, size: size);
      },
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  Widget _buildStatChip(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '$label: ${_fmt(value)}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _groupPosition(String? position) {
    switch (position) {
      case 'goleiro':
        return 'Goleiros';
      case 'ponta_esquerda':
      case 'ponta_direita':
        return 'Pontas';
      case 'armador_esquerdo':
      case 'armador_central':
      case 'armador_direito':
        return 'Meias / Armadores';
      case 'pivo':
        return 'Pivôs';
      default:
        return 'Outros';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupPlayersByPosition() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final player in _players) {
      final group = _groupPosition(player['primary_position'] as String?);
      grouped.putIfAbsent(group, () => []);
      grouped[group]!.add(player);
    }

    return grouped;
  }

  String? _photoUrlForAthlete(Map<String, dynamic> athlete) {
    final playerId = athlete['player_id'] as String?;
    if (playerId == null) return null;

    return _playerPhotoUrls[playerId];
  }

  void _openAthleteDetails(
    Map<String, dynamic> athlete, {
    required bool isGoalkeeper,
  }) {
    final athleteName = isGoalkeeper
        ? (athlete['goalkeeper_name'] as String? ?? 'Goleiro')
        : (athlete['player_name'] as String? ?? 'Jogador');

    showDialog(
      context: context,
      builder: (_) => TeamAthleteDetailsDialog(
        teamId: widget.teamId,
        athleteId: athlete['player_id'] as String,
        athleteName: athleteName,
        teamName: widget.teamName,
        isGoalkeeper: isGoalkeeper,
        stats: athlete,
        photoUrl: _photoUrlForAthlete(athlete),
      ),
    );
  }

  Widget _buildAthleteCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required String? photoUrl,
    required Color backgroundColor,
    required bool isGoalkeeper,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
              ),
              child: AthletePhotoAvatar(
                photoUrl: photoUrl,
                size: 42,
                fallbackIcon:
                    isGoalkeeper ? Icons.sports_handball : Icons.person_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedPlayers = _groupPlayersByPosition();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas do Time'),
      ),
      backgroundColor: const Color(0xFFF5F6F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSectionCard(
                        child: Row(
                          children: [
                            _buildShield(widget.shieldUrl),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.teamName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estatísticas gerais do time',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatChip('Chutes', _generalStats?['shots']),
                                _buildStatChip('Gols', _generalStats?['goals_scored']),
                                _buildStatChip(
                                  'Aprov. %',
                                  _fmtNum(_generalStats?['shot_percentage']),
                                ),
                                _buildStatChip('Chutes 9M', _generalStats?['shots_9m']),
                                _buildStatChip('Gols 9M', _generalStats?['goals_9m']),
                                _buildStatChip(
                                  'Aprov. 9M %',
                                  _fmtNum(_generalStats?['shot_percentage_9m']),
                                ),
                                _buildStatChip('Chutes 6M', _generalStats?['shots_6m']),
                                _buildStatChip('Gols 6M', _generalStats?['goals_6m']),
                                _buildStatChip(
                                  'Aprov. 6M %',
                                  _fmtNum(_generalStats?['shot_percentage_6m']),
                                ),
                                _buildStatChip('Chutes 7M', _generalStats?['shots_7m']),
                                _buildStatChip('Gols 7M', _generalStats?['goals_7m']),
                                _buildStatChip(
                                  'Aprov. 7M %',
                                  _fmtNum(_generalStats?['shot_percentage_7m']),
                                ),
                                _buildStatChip('Fora', _generalStats?['shots_out']),
                                _buildStatChip('Trave', _countShotsByResult('post')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mapa geral dos chutes do time',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GoalZoneHeatmapWidget(
                              breakdown: _teamGoalBreakdown,
                              isGoalkeeper: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mapa geral dos goleiros do time',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GoalZoneHeatmapWidget(
                              breakdown: _goalkeeperGoalBreakdown,
                              isGoalkeeper: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Goleiros',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _goalkeepers.isEmpty
                                ? const Text('Nenhum goleiro encontrado.')
                                : Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: _goalkeepers.map((gk) {
                                      return _buildAthleteCard(
                                        title: gk['goalkeeper_name'] as String? ??
                                            'Goleiro',
                                        subtitle:
                                            'Defesas: ${_fmt(gk['saves'])} • Gols sofridos: ${_fmt(gk['goals_conceded'])}',
                                        onTap: () => _openAthleteDetails(
                                          gk,
                                          isGoalkeeper: true,
                                        ),
                                        photoUrl: _photoUrlForAthlete(gk),
                                        backgroundColor: const Color(0xFFF4F8FF),
                                        isGoalkeeper: true,
                                      );
                                    }).toList(),
                                  ),
                            const SizedBox(height: 24),
                            ...groupedPlayers.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: entry.value.map((player) {
                                        return _buildAthleteCard(
                                          title: player['player_name'] as String? ??
                                              'Jogador',
                                          subtitle:
                                              'Gols: ${_fmt(player['goals'])} • Chutes: ${_fmt(player['shots'])}',
                                          onTap: () => _openAthleteDetails(
                                            player,
                                            isGoalkeeper: false,
                                          ),
                                          photoUrl: _photoUrlForAthlete(player),
                                          backgroundColor: const Color(0xFFF8F8F8),
                                          isGoalkeeper: false,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
