import 'package:flutter/material.dart';

import '../../repositories/shot_event_repository.dart';
import '../../widgets/goal_zone_selector.dart';
import '../../widgets/shot_zone_selector.dart';

class EditShotEventPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, String> teamNames;
  final Map<String, String> playerNames;
  final List<Map<String, dynamic>> homePlayers;
  final List<Map<String, dynamic>> awayPlayers;
  final List<Map<String, dynamic>> homeGoalkeepers;
  final List<Map<String, dynamic>> awayGoalkeepers;
  final String homeTeamId;
  final String awayTeamId;

  const EditShotEventPage({
    super.key,
    required this.event,
    required this.teamNames,
    required this.playerNames,
    required this.homePlayers,
    required this.awayPlayers,
    required this.homeGoalkeepers,
    required this.awayGoalkeepers,
    required this.homeTeamId,
    required this.awayTeamId,
  });

  @override
  State<EditShotEventPage> createState() => _EditShotEventPageState();
}

class _EditShotEventPageState extends State<EditShotEventPage> {
  final _repository = ShotEventRepository();

  bool _isSaving = false;
  String? _errorMessage;

  late String _teamId;
  late String? _playerId;
  late String? _goalkeeperPlayerId;
  late int? _zoneId;
  late int? _goalZoneId;
  late String _shotResult;
  late String _attackContext;
  late String _period;
  late int _minute;
  late int _second;

  @override
  void initState() {
    super.initState();

    _teamId = widget.event['team_id'] as String;
    _playerId = widget.event['player_id'] as String?;
    _goalkeeperPlayerId = widget.event['goalkeeper_player_id'] as String?;
    _zoneId = widget.event['zone_id'] as int?;
    _goalZoneId = widget.event['goal_zone_id'] as int?;
    _shotResult = widget.event['shot_result'] as String? ?? 'goal';
    _attackContext = widget.event['attack_context'] as String? ?? 'normal';
    _period = widget.event['period'] as String? ?? 'first_half';
    _minute = widget.event['minute'] as int? ?? 0;
    _second = widget.event['second'] as int? ?? 0;
  }

  bool _goalZoneIsRequired(String result) {
    return result == 'goal' || result == 'saved';
  }

  Widget _buildSelectorCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _currentPlayers {
    return _teamId == widget.homeTeamId ? widget.homePlayers : widget.awayPlayers;
  }

  List<Map<String, dynamic>> get _currentGoalkeepers {
    return _teamId == widget.homeTeamId
        ? widget.awayGoalkeepers
        : widget.homeGoalkeepers;
  }

  Future<void> _save() async {
    if (_playerId == null || _zoneId == null) {
      setState(() {
        _errorMessage = 'Selecione time, jogador e zona de chute.';
      });
      return;
    }

    if (_goalZoneIsRequired(_shotResult) && _goalZoneId == null) {
      setState(() {
        _errorMessage = 'Selecione a zona do gol.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _repository.updateShotEvent(
        widget.event['id'] as String,
        {
          'team_id': _teamId,
          'player_id': _playerId,
          'goalkeeper_player_id': _goalkeeperPlayerId,
          'zone_id': _zoneId,
          'goal_zone_id': _goalZoneIsRequired(_shotResult) ? _goalZoneId : null,
          'shot_result': _shotResult,
          'attack_context': _shotResult == 'goal' ? _attackContext : 'normal',
          'period': _period,
          'minute': _minute,
          'second': _second,
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao editar evento: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamOptions = [
      {
        'id': widget.homeTeamId,
        'name': widget.teamNames[widget.homeTeamId] ?? 'Mandante',
      },
      {
        'id': widget.awayTeamId,
        'name': widget.teamNames[widget.awayTeamId] ?? 'Visitante',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar evento de chute'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _teamId,
              decoration: const InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(),
              ),
              items: teamOptions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['id'] as String,
                      child: Text(item['name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _teamId = value!;
                  _playerId = null;
                  _goalkeeperPlayerId = null;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _playerId,
              decoration: const InputDecoration(
                labelText: 'Jogador',
                border: OutlineInputBorder(),
              ),
              items: _currentPlayers
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['id'] as String,
                      child: Text(
                        '${item['shirt_number'] ?? '?'} - ${item['full_name']}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _playerId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _goalkeeperPlayerId,
              decoration: const InputDecoration(
                labelText: 'Goleiro adversário',
                border: OutlineInputBorder(),
              ),
              items: _currentGoalkeepers
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['id'] as String,
                      child: Text(item['full_name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _goalkeeperPlayerId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final goalZoneEnabled = _goalZoneIsRequired(_shotResult);
                final sideBySide = constraints.maxWidth >= 760;

                final shotBoard = _buildSelectorCard(
                  title: 'Zona do chute',
                  child: RepaintBoundary(
                    child: ShotZoneSelector(
                      selectedZoneId: _zoneId,
                      onSelected: (value) {
                        setState(() {
                          _zoneId = _zoneId == value ? null : value;
                        });
                      },
                    ),
                  ),
                );

                final goalBoard = _buildSelectorCard(
                  title: 'Zona no gol',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Opacity(
                        opacity: goalZoneEnabled ? 1 : 0.42,
                        child: RepaintBoundary(
                          child: GoalZoneSelector(
                            selectedGoalZoneId: _goalZoneId,
                            onSelected: (value) {
                              setState(() {
                                _goalZoneId = _goalZoneId == value ? null : value;
                              });
                            },
                            enabled: goalZoneEnabled,
                          ),
                        ),
                      ),
                      if (!goalZoneEnabled) ...[
                        const SizedBox(height: 8),
                        const Text('Nao se aplica para este resultado.'),
                      ],
                    ],
                  ),
                );

                if (sideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: shotBoard),
                      const SizedBox(width: 12),
                      Expanded(child: goalBoard),
                    ],
                  );
                }

                return Column(
                  children: [
                    shotBoard,
                    const SizedBox(height: 12),
                    goalBoard,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _shotResult,
              decoration: const InputDecoration(
                labelText: 'Resultado',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'goal', child: Text('Gol')),
                DropdownMenuItem(value: 'out', child: Text('Fora')),
                DropdownMenuItem(value: 'post', child: Text('Trave')),
                DropdownMenuItem(value: 'saved', child: Text('Defesa')),
                DropdownMenuItem(value: 'blocked', child: Text('Bloqueado')),
              ],
              onChanged: (value) {
                setState(() {
                  _shotResult = value!;
                  if (_shotResult != 'goal') {
                    _attackContext = 'normal';
                  }
                  if (!_goalZoneIsRequired(_shotResult)) {
                    _goalZoneId = null;
                  }
                });
              },
            ),
            if (_shotResult == 'goal') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _attackContext,
                decoration: const InputDecoration(
                  labelText: 'Tipo do gol',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Gol normal')),
                  DropdownMenuItem(value: 'contra_ataque', child: Text('Contra-ataque')),
                ],
                onChanged: (value) {
                  setState(() {
                    _attackContext = value!;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _period,
              decoration: const InputDecoration(
                labelText: 'Período',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'first_half', child: Text('1º tempo')),
                DropdownMenuItem(value: 'second_half', child: Text('2º tempo')),
                DropdownMenuItem(value: 'extra_time_1', child: Text('Prorrogação 1')),
                DropdownMenuItem(value: 'extra_time_2', child: Text('Prorrogação 2')),
                DropdownMenuItem(value: 'penalties', child: Text('Tiros')),
              ],
              onChanged: (value) {
                setState(() {
                  _period = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _minute.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Minuto',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _minute = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _second.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Segundo',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _second = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Salvar alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
