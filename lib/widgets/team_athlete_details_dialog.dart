import 'package:flutter/material.dart';

import '../repositories/match_statistics_repository.dart';
import 'athlete_photo_avatar.dart';
import 'match_goal_zone_breakdown_section.dart';
import 'team_athlete_goal_zone_breakdown_section.dart';

class TeamAthleteDetailsDialog extends StatefulWidget {
  final String athleteId;
  final String athleteName;
  final String teamName;
  final bool isGoalkeeper;
  final Map<String, dynamic> stats;
  final String teamId;
  final String? photoUrl;

  const TeamAthleteDetailsDialog({
    super.key,
    required this.athleteId,
    required this.athleteName,
    required this.teamName,
    required this.isGoalkeeper,
    required this.stats,
    required this.teamId,
    required this.photoUrl,
  });

  @override
  State<TeamAthleteDetailsDialog> createState() =>
      _TeamAthleteDetailsDialogState();
}

class _TeamAthleteDetailsDialogState extends State<TeamAthleteDetailsDialog> {
  final _repository = MatchStatisticsRepository();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _playerZoneStats = [];
  List<Map<String, dynamic>> _playerGoalZoneStats = [];
  List<Map<String, dynamic>> _goalkeeperGoalZoneStats = [];

  @override
  void initState() {
    super.initState();
    _loadExtraData();
  }

  Future<void> _loadExtraData() async {
    try {
      if (widget.isGoalkeeper) {
        final goalkeeperGoalZones = await _repository.getAllGoalkeeperGoalZoneStatsByPlayer(
          widget.athleteId,
        );

        if (!mounted) return;

        setState(() {
          _goalkeeperGoalZoneStats = goalkeeperGoalZones;
          _isLoading = false;
        });
      } else {
        final playerZones = await _repository.getAllPlayerZoneStatsByPlayer(
          widget.athleteId,
        );
        final playerGoalZones = await _repository.getAllPlayerGoalZoneStatsByPlayer(
          widget.athleteId,
        );

        if (!mounted) return;

        setState(() {
          _playerZoneStats = playerZones;
          _playerGoalZoneStats = playerGoalZones;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar detalhes: $e';
        _isLoading = false;
      });
    }
  }

  String _fmt(dynamic value) => '${value ?? 0}';

  String _goalZoneLabel(dynamic value) {
    if (value == null) return '-';
    if (value is int) return 'G${value.toString().padLeft(2, '0')}';

    final text = value.toString().trim().toUpperCase();
    if (text.startsWith('G')) return text;
    if (text.startsWith('Z')) return 'G${text.substring(1)}';

    final parsed = int.tryParse(text);
    if (parsed != null) {
      return 'G${parsed.toString().padLeft(2, '0')}';
    }

    return text;
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoBlock({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  String _groupLabel(String? zoneCode) {
    switch (zoneCode) {
      case 'Z07':
      case 'Z08':
      case 'Z09':
        return 'Chutes dos 9m';
      case 'Z02':
      case 'Z03':
      case 'Z04':
        return 'Chutes dos 6m';
      case 'Z01':
      case 'Z05':
        return 'Chutes de ponta';
      case '7M':
        return 'Chutes de 7m';
      default:
        return 'Outras zonas';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByZoneCode(
    List<Map<String, dynamic>> items,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final item in items) {
      final zoneCode = item['zone_code'] as String?;
      final group = _groupLabel(zoneCode);
      grouped.putIfAbsent(group, () => []);
      grouped[group]!.add(item);
    }

    return grouped;
  }

  Widget _buildGroupedCards({
    required String title,
    required Map<String, List<Map<String, dynamic>>> grouped,
    required bool isGoalkeeper,
    required bool isGoalMap,
  }) {
    if (grouped.isEmpty) {
      return _buildInfoBlock(
        title: title,
        children: const [Text('Sem dados disponíveis.')],
      );
    }

    return _buildInfoBlock(
      title: title,
      children: grouped.entries.map((entry) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: entry.value.map((z) {
                  return Container(
                    width: 220,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGoalMap
                              ? '${z['zone_code']} → ${_goalZoneLabel(z['goal_zone_code'])}'
                              : '${z['zone_code']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isGoalkeeper && isGoalMap) ...[
                          Text('Chutes sofridos: ${_fmt(z['shots_faced'])}'),
                          Text('Gols sofridos: ${_fmt(z['goals_conceded'])}'),
                          Text('Defesas: ${_fmt(z['saves'])}'),
                        ] else if (!isGoalkeeper && isGoalMap) ...[
                          Text('Chutes: ${_fmt(z['shots'])}'),
                          Text('Gols: ${_fmt(z['goals'])}'),
                        ] else ...[
                          Text('Chutes: ${_fmt(z['shots'])}'),
                          Text('Gols: ${_fmt(z['goals'])}'),
                          Text('Aprov.: ${_fmt(z['shot_percentage'])}%'),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AthletePhotoAvatar(
                              photoUrl: widget.photoUrl,
                              size: 96,
                              fallbackIcon: widget.isGoalkeeper
                                  ? Icons.sports_handball
                                  : Icons.person_outline,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.athleteName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Time: ${widget.teamName}',
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildInfoBlock(
                                  title: 'Resumo',
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: widget.isGoalkeeper
                                          ? [
                                              _buildStatChip('Chutes sofridos', widget.stats['shots_faced']),
                                              _buildStatChip('Defesas', widget.stats['saves']),
                                              _buildStatChip('Gols sofridos', widget.stats['goals_conceded']),
                                              _buildStatChip('% Defesa', widget.stats['save_percentage']),
                                            ]
                                          : [
                                              _buildStatChip('Chutes', widget.stats['shots']),
                                              _buildStatChip('Gols', widget.stats['goals']),
                                              _buildStatChip('Aprov. %', widget.stats['shot_percentage']),
                                              _buildStatChip('Chutes 9M', widget.stats['shots_9m']),
                                              _buildStatChip('Gols 9M', widget.stats['goals_9m']),
                                              _buildStatChip('Aprov. 9M %', widget.stats['shot_percentage_9m']),
                                              _buildStatChip('Chutes 7M', widget.stats['shots_7m']),
                                              _buildStatChip('Gols 7M', widget.stats['goals_7m']),
                                              _buildStatChip('Aprov. 7M %', widget.stats['shot_percentage_7m']),
                                              _buildStatChip('Gols CA', widget.stats['counter_attack_goals']),
                                              _buildStatChip('Fora', widget.stats['shots_out']),
                                              _buildStatChip('Bloqueados', widget.stats['shots_blocked']),
                                            ],
                                    ),
                                  ],
                                ),
                                if (!widget.isGoalkeeper)
                                  _buildInfoBlock(
                                    title: 'Disciplina',
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildStatChip('2 min', widget.stats['suspensions_2min']),
                                          _buildStatChip('Amarelos', widget.stats['yellow_cards']),
                                          _buildStatChip('Vermelhos', widget.stats['red_cards']),
                                          _buildStatChip('Azuis', widget.stats['blue_cards']),
                                        ],
                                      ),
                                    ],
                                  ),
                                TeamAthleteGoalZoneBreakdownSection(
                                    teamId: widget.teamId,
                                    athleteId: widget.athleteId,
                                    isGoalkeeper: widget.isGoalkeeper,
                                    title: widget.isGoalkeeper
                                        ? 'Mapa das defesas no gol'
                                        : 'Mapa do gol',
                                    ),
                                if (widget.isGoalkeeper)
                                  _buildGroupedCards(
                                    title: 'Zona de chute → Zona no gol sofrido',
                                    grouped: _groupByZoneCode(_goalkeeperGoalZoneStats),
                                    isGoalkeeper: true,
                                    isGoalMap: true,
                                  )
                                else ...[
                                  _buildGroupedCards(
                                    title: 'Zonas de chute',
                                    grouped: _groupByZoneCode(_playerZoneStats),
                                    isGoalkeeper: false,
                                    isGoalMap: false,
                                  ),
                                  _buildGroupedCards(
                                    title: 'Zona de chute → Zona no gol',
                                    grouped: _groupByZoneCode(_playerGoalZoneStats),
                                    isGoalkeeper: false,
                                    isGoalMap: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Fechar'),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
