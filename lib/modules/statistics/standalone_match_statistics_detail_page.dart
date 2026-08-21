import 'package:flutter/material.dart';

import '../../repositories/standalone_scout_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';

class StandaloneMatchStatisticsDetailPage extends StatefulWidget {
  final Map<String, dynamic> match;

  const StandaloneMatchStatisticsDetailPage({
    super.key,
    required this.match,
  });

  @override
  State<StandaloneMatchStatisticsDetailPage> createState() =>
      _StandaloneMatchStatisticsDetailPageState();
}

class _StandaloneMatchStatisticsDetailPageState
    extends State<StandaloneMatchStatisticsDetailPage> {
  final _repository = StandaloneScoutRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _teamStats = [];
  List<Map<String, dynamic>> _playerStats = [];
  List<Map<String, dynamic>> _goalkeeperStats = [];
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final matchId = widget.match['id'] as String;
      final results = await Future.wait([
        _repository.getTeamStats(matchId),
        _repository.getPlayerStats(matchId),
        _repository.getGoalkeeperStats(matchId),
        _repository.getEvents(matchId),
      ]);

      if (!mounted) return;

      setState(() {
        _teamStats = results[0];
        _playerStats = results[1];
        _goalkeeperStats = results[2];
        _events = results[3];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar estatísticas avulsas: $e';
        _isLoading = false;
      });
    }
  }

  String _fmt(dynamic value) => '${value ?? 0}';

  String _formatPercent(dynamic value) {
    if (value == null) return '0%';
    final parsed = num.tryParse(value.toString()) ?? 0;
    return '${parsed.toStringAsFixed(1)}%';
  }

  String _formatClock(Map<String, dynamic> event) {
    final minute = event['minute'] as int? ?? 0;
    final second = event['second'] as int? ?? 0;
    return '${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  String _periodLabel(String? period) {
    switch (period) {
      case 'second_half':
        return '2º tempo';
      case 'extra_1':
        return 'Prorrogação 1';
      case 'extra_2':
        return 'Prorrogação 2';
      case 'shootout':
        return 'Tiros';
      case 'first_half':
      default:
        return '1º tempo';
    }
  }

  String _eventLabel(String? eventType) {
    switch (eventType) {
      case 'goal':
        return 'Gol';
      case 'out':
        return 'Fora';
      case 'post':
        return 'Trave';
      case 'saved':
        return 'Defesa';
      case 'pass_error':
        return 'Erro de passe';
      case 'technical_error':
        return 'Erro técnico';
      default:
        return eventType ?? '-';
    }
  }

  String _goalZoneLabel(dynamic value) {
    if (value == null) return '-';
    final zoneId = value is int ? value : int.tryParse(value.toString());
    if (zoneId == null) return '-';
    if (zoneId <= 9) return 'G${zoneId.toString().padLeft(2, '0')}';
    if (zoneId >= 11 && zoneId <= 13) {
      return 'F${(zoneId - 10).toString().padLeft(2, '0')}';
    }
    if (zoneId >= 15 && zoneId <= 20) {
      return 'F${(zoneId - 11).toString().padLeft(2, '0')}';
    }
    return '-';
  }

  String _teamNameFromEvent(Map<String, dynamic> event) {
    final team = event['standalone_team'];
    if (team is Map && team['name'] != null) {
      return team['name'].toString();
    }
    return '-';
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppThemeColors.line),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppThemeColors.ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
        color: AppThemeColors.panelAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeColors.line),
      ),
      child: Text(
        '$label: ${_fmt(value)}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByTeam(
    List<Map<String, dynamic>> rows,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final teamName = row['team_name'] as String? ?? '-';
      grouped.putIfAbsent(teamName, () => []).add(row);
    }
    return grouped;
  }

  Widget _buildHeader() {
    final homeName = widget.match['home_team_name'] as String? ?? 'Time A';
    final awayName = widget.match['away_team_name'] as String? ?? 'Time B';
    final homeScore = widget.match['home_score'] as int? ?? 0;
    final awayScore = widget.match['away_score'] as int? ?? 0;

    return _buildSectionCard(
      child: Column(
        children: [
          const Text(
            'Partida avulsa',
            style: TextStyle(
              color: AppThemeColors.slate,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  homeName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  '$homeScore x $awayScore',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppThemeColors.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  awayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStats() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo por time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (_teamStats.isEmpty)
            const Text('Nenhum evento de time encontrado.')
          else
            ..._teamStats.map((team) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team['team_name'] as String? ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatChip('Ataques', team['attacks']),
                        _buildStatChip('Arremessos', team['shots']),
                        _buildStatChip('Gols', team['goals']),
                        _buildStatChip('Trave', team['posts']),
                        _buildStatChip('Fora', team['outs']),
                        _buildStatChip('Defesas', team['saved_shots']),
                        _buildStatChip('Erro passe', team['pass_errors']),
                        _buildStatChip('Erro técnico', team['technical_errors']),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPlayerStats() {
    return _buildSectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              'Jogadores por camisa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          if (_playerStats.isEmpty)
            const Padding(
              padding: EdgeInsets.all(4),
              child: Text('Nenhum arremesso registrado.'),
            )
          else
            ..._groupByTeam(_playerStats).entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Camisa')),
                          DataColumn(label: Text('Chutes')),
                          DataColumn(label: Text('Gols')),
                          DataColumn(label: Text('Trave')),
                          DataColumn(label: Text('Fora')),
                          DataColumn(label: Text('Defesa')),
                          DataColumn(label: Text('% Gol')),
                        ],
                        rows: entry.value.map((player) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(player['player_number']?.toString() ?? '-'),
                              ),
                              DataCell(Text(_fmt(player['shots']))),
                              DataCell(Text(_fmt(player['goals']))),
                              DataCell(Text(_fmt(player['posts']))),
                              DataCell(Text(_fmt(player['outs']))),
                              DataCell(Text(_fmt(player['saved_shots']))),
                              DataCell(
                                Text(_formatPercent(player['goal_percentage'])),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEvents() {
    return _buildSectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              'Histórico de eventos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          if (_events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(4),
              child: Text('Nenhum evento encontrado.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _events.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = _events[index];
                final isShot = event['event_kind'] == 'shot';
                final shotZone = event['shot_zone_id'] == null
                    ? '-'
                    : 'Z${event['shot_zone_id'].toString().padLeft(2, '0')}';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isShot
                        ? AppThemeColors.primary.withValues(alpha: 0.12)
                        : AppThemeColors.secondary.withValues(alpha: 0.16),
                    foregroundColor:
                        isShot ? AppThemeColors.primary : AppThemeColors.secondary,
                    child: isShot
                        ? Text(event['player_number']?.toString() ?? '-')
                        : const Icon(Icons.error_outline),
                  ),
                  title: Text(
                    '${_teamNameFromEvent(event)} - ${_eventLabel(event['event_type'] as String?)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    isShot
                        ? '${_periodLabel(event['period'] as String?)} ${_formatClock(event)} | '
                            '$shotZone -> ${_goalZoneLabel(event['goal_zone_id'])}'
                        : '${_periodLabel(event['period'] as String?)} ${_formatClock(event)}',
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGoalkeeperStats() {
    return _buildSectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              'Goleiros por camisa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          if (_goalkeeperStats.isEmpty)
            const Padding(
              padding: EdgeInsets.all(4),
              child: Text('Nenhuma defesa registrada com goleiro.'),
            )
          else
            ..._groupByTeam(_goalkeeperStats).entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Camisa')),
                          DataColumn(label: Text('Defesas')),
                        ],
                        rows: entry.value.map((goalkeeper) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  goalkeeper['goalkeeper_number']?.toString() ??
                                      '-',
                                ),
                              ),
                              DataCell(Text(_fmt(goalkeeper['saves']))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas avulsas'),
      ),
      body: AppBackdrop(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : RefreshIndicator(
                    onRefresh: _loadStats,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildTeamStats(),
                        const SizedBox(height: 14),
                        _buildPlayerStats(),
                        const SizedBox(height: 14),
                        _buildGoalkeeperStats(),
                        const SizedBox(height: 14),
                        _buildEvents(),
                      ],
                    ),
                  ),
      ),
    );
  }
}
