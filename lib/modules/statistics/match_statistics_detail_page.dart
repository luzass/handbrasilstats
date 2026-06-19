import 'package:flutter/material.dart';

import '../../models/player_model.dart';
import '../../models/match_statistics_list_item_model.dart';
import '../../repositories/match_statistics_repository.dart';
import '../../repositories/player_repository.dart';
import '../../repositories/shot_event_repository.dart';
import '../../widgets/athlete_photo_avatar.dart';
import '../../widgets/match_goal_zone_breakdown_section.dart';

class MatchStatisticsDetailPage extends StatefulWidget {
  final MatchStatisticsListItemModel match;

  const MatchStatisticsDetailPage({
    super.key,
    required this.match,
  });

  @override
  State<MatchStatisticsDetailPage> createState() =>
      _MatchStatisticsDetailPageState();
}

class _MatchStatisticsDetailPageState
    extends State<MatchStatisticsDetailPage> {
  final _repository = MatchStatisticsRepository();
  final _playerRepository = PlayerRepository();
  final _shotEventRepository = ShotEventRepository();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _liveStats = [];
  List<Map<String, dynamic>> _goalkeeperStats = [];
  List<Map<String, dynamic>> _playerStats = [];
  List<Map<String, dynamic>> _playerZoneStats = [];
  List<Map<String, dynamic>> _playerGoalZoneStats = [];
  List<Map<String, dynamic>> _goalkeeperGoalZoneStats = [];
  List<Map<String, dynamic>> _shotEvents = [];
  Map<String, String?> _playerPhotoUrls = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        _repository.getMatchLiveStats(widget.match.id),
        _repository.getMatchGoalkeeperStats(widget.match.id),
        _repository.getMatchPlayerStats(widget.match.id),
        _repository.getMatchPlayerZoneStats(widget.match.id),
        _repository.getMatchPlayerGoalZoneStats(widget.match.id),
        _repository.getMatchGoalkeeperGoalZoneStats(widget.match.id),
        _shotEventRepository.getMatchEvents(widget.match.id),
        _playerRepository.getPlayers(),
      ]);

      final allPlayers = results[7] as List<PlayerModel>;
      final photoMap = <String, String?>{};
      for (final player in allPlayers) {
        photoMap[player.id] = player.photoUrl;
      }

      if (!mounted) return;

      setState(() {
        _liveStats = results[0] as List<Map<String, dynamic>>;
        _goalkeeperStats = results[1] as List<Map<String, dynamic>>;
        _playerStats = results[2] as List<Map<String, dynamic>>;
        _playerZoneStats = results[3] as List<Map<String, dynamic>>;
        _playerGoalZoneStats = results[4] as List<Map<String, dynamic>>;
        _goalkeeperGoalZoneStats = results[5] as List<Map<String, dynamic>>;
        _shotEvents = results[6] as List<Map<String, dynamic>>;
        _playerPhotoUrls = photoMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar estatísticas: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _findStats(String teamId) {
    try {
      return _liveStats.firstWhere((item) => item['team_id'] == teamId);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _goalkeepersByTeam(String teamId) {
    return _goalkeeperStats.where((e) => e['team_id'] == teamId).toList();
  }

  List<Map<String, dynamic>> _playersByTeam(String teamId) {
    return _playerStats.where((e) => e['team_id'] == teamId).toList();
  }

  List<Map<String, dynamic>> _playerZones(String playerId) {
    return _playerZoneStats.where((e) => e['player_id'] == playerId).toList();
  }

  List<Map<String, dynamic>> _playerGoalZones(String playerId) {
    return _playerGoalZoneStats.where((e) => e['player_id'] == playerId).toList();
  }

  List<Map<String, dynamic>> _goalkeeperGoalZones(String playerId) {
    return _goalkeeperGoalZoneStats.where((e) => e['player_id'] == playerId).toList();
  }

  String _fmt(dynamic value) => '${value ?? 0}';

  int _countTeamShotsByResult(String teamId, String result) {
    return _shotEvents.where((item) {
      return item['team_id'] == teamId && item['shot_result'] == result;
    }).length;
  }

  int _countPlayerShotsByResult(String playerId, String result) {
    return _shotEvents.where((item) {
      return item['player_id'] == playerId && item['shot_result'] == result;
    }).length;
  }

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

  String? _photoUrlForAthlete(Map<String, dynamic> athlete) {
    final playerId = athlete['player_id'] as String?;
    if (playerId == null) return null;

    return _playerPhotoUrls[playerId];
  }

  Widget _buildShield(String? url, {double size = 72}) {
    if (url == null || url.isEmpty) {
      return Icon(Icons.shield_outlined, size: size);
    }

    return Image.network(
      url,
      height: size,
      width: size,
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildModalSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
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
          _buildModalSectionTitle(title),
          ...children,
        ],
      ),
    );
  }

  String _goalkeeperShotGroupLabel(String? zoneCode) {
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

Map<String, List<Map<String, dynamic>>> _groupGoalkeeperGoalZones(
  List<Map<String, dynamic>> goalZones,
) {
  final grouped = <String, List<Map<String, dynamic>>>{};

  for (final item in goalZones) {
    final zoneCode = item['zone_code'] as String?;
    final group = _goalkeeperShotGroupLabel(zoneCode);
    grouped.putIfAbsent(group, () => []);
    grouped[group]!.add(item);
  }

  return grouped;
}

Widget _buildGoalkeeperZoneGroupCard({
  required String title,
  required List<Map<String, dynamic>> items,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
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
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((z) {
            return Container(
              width: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${z['zone_code']} → ${_goalZoneLabel(z['goal_zone_code'])}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Chutes sofridos: ${_fmt(z['shots_faced'])}'),
                  Text('Gols sofridos: ${_fmt(z['goals_conceded'])}'),
                  Text('Defesas: ${_fmt(z['saves'])}'),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

String _playerShotGroupLabel(String? zoneCode) {
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

Map<String, List<Map<String, dynamic>>> _groupPlayerZones(
  List<Map<String, dynamic>> zones,
) {
  final grouped = <String, List<Map<String, dynamic>>>{};

  for (final item in zones) {
    final zoneCode = item['zone_code'] as String?;
    final group = _playerShotGroupLabel(zoneCode);
    grouped.putIfAbsent(group, () => []);
    grouped[group]!.add(item);
  }

  return grouped;
}

Map<String, List<Map<String, dynamic>>> _groupPlayerGoalZones(
  List<Map<String, dynamic>> goalZones,
) {
  final grouped = <String, List<Map<String, dynamic>>>{};

  for (final item in goalZones) {
    final zoneCode = item['zone_code'] as String?;
    final group = _playerShotGroupLabel(zoneCode);
    grouped.putIfAbsent(group, () => []);
    grouped[group]!.add(item);
  }

  return grouped;
}

Widget _buildPlayerZoneGroupCard({
  required String title,
  required List<Map<String, dynamic>> items,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
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
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((z) {
            return Container(
              width: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    z['zone_code'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Chutes: ${_fmt(z['shots'])}'),
                  Text('Gols: ${_fmt(z['goals'])}'),
                  Text('Aprov.: ${_fmt(z['shot_percentage'])}%'),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

Widget _buildPlayerGoalZoneGroupCard({
  required String title,
  required List<Map<String, dynamic>> items,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
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
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((z) {
            return Container(
              width: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${z['zone_code']} → ${_goalZoneLabel(z['goal_zone_code'])}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Chutes: ${_fmt(z['shots'])}'),
                  Text('Gols: ${_fmt(z['goals'])}'),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

  Widget _buildHeader() {
    return _buildSectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildShield(widget.match.homeTeamShieldUrl, size: 84),
                const SizedBox(height: 8),
                Text(
                  widget.match.homeTeamName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '${widget.match.scoreHome} x ${widget.match.scoreAway}',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildShield(widget.match.awayTeamShieldUrl, size: 84),
                const SizedBox(height: 8),
                Text(
                  widget.match.awayTeamName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralStatsCard() {
    final homeStats = _findStats(widget.match.homeTeamId);
    final awayStats = _findStats(widget.match.awayTeamId);

    Widget statRow(String label, dynamic left, dynamic right) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _fmt(left),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                _fmt(right),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildSectionCard(
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Estatísticas gerais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 14),
          statRow('Chutes', homeStats?['shots'], awayStats?['shots']),
          statRow(
            'Aproveitamento %',
            homeStats?['shot_percentage'],
            awayStats?['shot_percentage'],
          ),
          statRow('Gols 9M', homeStats?['goals_9m'], awayStats?['goals_9m']),
          statRow(
            'Aprov. 9M %',
            homeStats?['shot_percentage_9m'],
            awayStats?['shot_percentage_9m'],
          ),
          statRow('Gols 7M', homeStats?['goals_7m'], awayStats?['goals_7m']),
          statRow(
            'Aprov. 7M %',
            homeStats?['shot_percentage_7m'],
            awayStats?['shot_percentage_7m'],
          ),
          statRow(
            'Gols Contra-Ataque',
            homeStats?['counter_attack_goals'],
            awayStats?['counter_attack_goals'],
          ),
          statRow('Fora', homeStats?['shots_out'], awayStats?['shots_out']),
          statRow(
            'Trave',
            _countTeamShotsByResult(widget.match.homeTeamId, 'post'),
            _countTeamShotsByResult(widget.match.awayTeamId, 'post'),
          ),
          statRow(
            'Defesas sofridas',
            homeStats?['shots_saved'],
            awayStats?['shots_saved'],
          ),
          statRow(
            'Bloqueados',
            homeStats?['shots_blocked'],
            awayStats?['shots_blocked'],
          ),
        ],
      ),
    );
  }


  void _openPlayerDetails(Map<String, dynamic> player) {
    final zones = _playerZones(player['player_id'] as String);
    final goalZones = _playerGoalZones(player['player_id'] as String);

    final groupedZones = _groupPlayerZones(zones);
    final groupedGoalZones = _groupPlayerGoalZones(goalZones);

  
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850, maxHeight: 760),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    AthletePhotoAvatar(
                      photoUrl: _photoUrlForAthlete(player),
                      size: 96,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player['player_name'] as String? ?? 'Jogador',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Time: ${player['team_name']}',
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
                              children: [
                                _buildStatChip('Chutes', player['shots']),
                                _buildStatChip('Gols', player['goals']),
                                _buildStatChip('Aprov. %', player['shot_percentage']),
                                _buildStatChip('Chutes 9M', player['shots_9m']),
                                _buildStatChip('Gols 9M', player['goals_9m']),
                                _buildStatChip('Aprov. 9M %', player['shot_percentage_9m']),
                                _buildStatChip('Chutes 7M', player['shots_7m']),
                                _buildStatChip('Gols 7M', player['goals_7m']),
                                _buildStatChip('Aprov. 7M %', player['shot_percentage_7m']),
                                _buildStatChip('Gols CA', player['counter_attack_goals']),
                                _buildStatChip('Fora', player['shots_out']),
                                _buildStatChip(
                                  'Trave',
                                  _countPlayerShotsByResult(
                                    player['player_id'] as String,
                                    'post',
                                  ),
                                ),
                                _buildStatChip('Bloqueados', player['shots_blocked']),
                              ],
                            ),
                          ],
                        ),
                        _buildInfoBlock(
                          title: 'Disciplina',
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatChip('2 min', player['suspensions_2min']),
                                _buildStatChip('Amarelos', player['yellow_cards']),
                                _buildStatChip('Vermelhos', player['red_cards']),
                                _buildStatChip('Azuis', player['blue_cards']),
                              ],
                            ),
                          ],
                        ),
                        MatchGoalZoneBreakdownSection(
                          matchId: widget.match.id,
                          athleteId: player['player_id'] as String,
                          isGoalkeeper: false,
                          title: 'Mapa do gol',
                        ),
                        _buildInfoBlock(
                          title: 'Zonas de chute',
                          children: zones.isEmpty
                              ? [const Text('Sem dados por zona.')]
                              : groupedZones.entries.map((entry) {
                                   return _buildPlayerZoneGroupCard(
                                     title: entry.key,
                                     items: entry.value,
                                   );
                              }).toList(),
                        ),
                        _buildInfoBlock(
                          title: 'Zona de chute → Zona no gol',
                          children: goalZones.isEmpty
                              ? [const Text('Sem dados de zona no gol.')]
                              : groupedGoalZones.entries.map((entry) {
                                   return _buildPlayerGoalZoneGroupCard(
                                     title: entry.key,
                                     items: entry.value,
                                   );
                                }).toList(),

                        ),
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
      ),
    );
  }

  void _openGoalkeeperDetails(Map<String, dynamic> goalkeeper) {
    final goalZones = _goalkeeperGoalZones(goalkeeper['player_id'] as String);
    final groupedGoalZones = _groupGoalkeeperGoalZones(goalZones);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850, maxHeight: 760),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AthletePhotoAvatar(
                      photoUrl: _photoUrlForAthlete(goalkeeper),
                      size: 96,
                      fallbackIcon: Icons.sports_handball,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goalkeeper['goalkeeper_name'] as String? ?? 'Goleiro',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Time: ${goalkeeper['team_name']}',
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
                              children: [
                                _buildStatChip('Chutes sofridos', goalkeeper['shots_faced']),
                                _buildStatChip('Defesas', goalkeeper['saves']),
                                _buildStatChip('Gols sofridos', goalkeeper['goals_conceded']),
                                _buildStatChip('% Defesa', goalkeeper['save_percentage']),
                                _buildStatChip('Chutes 9M', goalkeeper['shots_faced_9m']),
                                _buildStatChip('Defesas 9M', goalkeeper['saves_9m']),
                                _buildStatChip('% Defesa 9M', goalkeeper['save_percentage_9m']),
                                _buildStatChip('Chutes 7M', goalkeeper['shots_faced_7m']),
                                _buildStatChip('Defesas 7M', goalkeeper['saves_7m']),
                                _buildStatChip('% Defesa 7M', goalkeeper['save_percentage_7m']),
                              ],
                            ),
                          ],
                        ),
                        _buildInfoBlock(
                          title: 'Contra-ataque',
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatChip(
                                  'CA sofridos',
                                  goalkeeper['counter_attack_shots_faced'],
                                ),
                                _buildStatChip(
                                  'Defesas CA',
                                  goalkeeper['counter_attack_saves'],
                                ),
                                _buildStatChip(
                                  '% Defesa CA',
                                  goalkeeper['save_percentage_counter_attack'],
                                ),
                              ],
                            ),
                          ],
                        ),
                        MatchGoalZoneBreakdownSection(
                          matchId: widget.match.id,
                          athleteId: goalkeeper['player_id'] as String,
                          isGoalkeeper: true,
                          title: 'Mapa das defesas no gol',
                        ),
                        _buildInfoBlock(
                        
                          title: 'Zona de chute → Zona no gol sofrido',
                          children: goalZones.isEmpty
                              ? [const Text('Sem dados de zona no gol.')]
                              : groupedGoalZones.entries.map((entry) {
                                  return _buildGoalkeeperZoneGroupCard(
                                    title: entry.key,
                                    items: entry.value,
                                  );
                                }).toList(),
                        ),
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
      ),
    );
  }

  Widget _buildMiniCard({
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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

  Widget _buildTeamSection({
    required String teamId,
    required String teamName,
    required String? shieldUrl,
  }) {
    final goalkeepers = _goalkeepersByTeam(teamId);
    final players = _playersByTeam(teamId);

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShield(shieldUrl, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  teamName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Goleiros',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          goalkeepers.isEmpty
              ? const Text('Nenhum goleiro com estatística nesta partida.')
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: goalkeepers.map((gk) {
                    return _buildMiniCard(
                      title: gk['goalkeeper_name'] as String? ?? 'Goleiro',
                      subtitle:
                          'Defesas: ${_fmt(gk['saves'])} • Gols sofridos: ${_fmt(gk['goals_conceded'])}',
                      photoUrl: _photoUrlForAthlete(gk),
                      backgroundColor: const Color(0xFFF4F8FF),
                      isGoalkeeper: true,
                      onTap: () => _openGoalkeeperDetails(gk),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 24),
          const Text(
            'Jogadores',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          players.isEmpty
              ? const Text('Nenhum jogador com estatística nesta partida.')
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: players.map((player) {
                    return _buildMiniCard(
                      title: player['player_name'] as String? ?? 'Jogador',
                      subtitle:
                          'Gols: ${_fmt(player['goals'])} • Chutes: ${_fmt(player['shots'])}',
                      photoUrl: _photoUrlForAthlete(player),
                      backgroundColor: const Color(0xFFF8F8F8),
                      isGoalkeeper: false,
                      onTap: () => _openPlayerDetails(player),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Estatísticas da Partida'),
        ),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas da Partida'),
      ),
      backgroundColor: const Color(0xFFF5F6F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildGeneralStatsCard(),
            const SizedBox(height: 16),
            _buildTeamSection(
              teamId: widget.match.homeTeamId,
              teamName: widget.match.homeTeamName,
              shieldUrl: widget.match.homeTeamShieldUrl,
            ),
            const SizedBox(height: 16),
            _buildTeamSection(
              teamId: widget.match.awayTeamId,
              teamName: widget.match.awayTeamName,
              shieldUrl: widget.match.awayTeamShieldUrl,
            ),
          ],
        ),
      ),
    );
  }
}
