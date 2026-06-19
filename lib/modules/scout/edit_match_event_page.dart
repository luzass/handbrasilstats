import 'package:flutter/material.dart';

import '../../models/match_event_model.dart';
import '../../repositories/match_event_repository.dart';

class EditMatchEventPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, String> teamNames;
  final Map<String, String> playerNames;
  final List<Map<String, dynamic>> homePlayers;
  final List<Map<String, dynamic>> awayPlayers;
  final List<Map<String, dynamic>> homeGoalkeepers;
  final List<Map<String, dynamic>> awayGoalkeepers;
  final String homeTeamId;
  final String awayTeamId;

  const EditMatchEventPage({
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
  State<EditMatchEventPage> createState() => _EditMatchEventPageState();
}

class _EditMatchEventPageState extends State<EditMatchEventPage> {
  final _repository = MatchEventRepository();

  bool _isSaving = false;
  String? _errorMessage;

  late String _teamId;
  late String? _playerId;
  late String _eventType;
  late String _period;
  late int _minute;
  late int _second;

  @override
  void initState() {
    super.initState();

    _teamId = widget.event['team_id'] as String;
    _playerId = widget.event['player_id'] as String?;
    _eventType = widget.event['event_type'] as String? ?? 'suspension_2min';
    _period = widget.event['period'] as String? ?? 'first_half';
    _minute = widget.event['minute'] as int? ?? 0;
    _second = widget.event['second'] as int? ?? 0;
  }

  bool get _needsPlayer => _eventType != 'timeout';

  List<Map<String, dynamic>> get _currentPlayers {
    if (_teamId == widget.homeTeamId) {
      return [...widget.homePlayers, ...widget.homeGoalkeepers];
    }
    return [...widget.awayPlayers, ...widget.awayGoalkeepers];
  }

  Future<void> _save() async {
    if (_needsPlayer && _playerId == null) {
      setState(() {
        _errorMessage = 'Selecione o jogador.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final model = MatchEventModel(
        id: widget.event['id'] as String,
        matchId: widget.event['match_id'] as String,
        competitionId: widget.event['competition_id'] as String,
        teamId: _teamId,
        playerId: _needsPlayer ? _playerId : null,
        eventType: _eventType,
        period: _period,
        minute: _minute,
        second: _second,
        sequenceOrder: widget.event['sequence_order'] as int? ?? 1,
        createdBy: widget.event['created_by'] as String?,
        notes: widget.event['notes'] as String?,
      );

      await _repository.updateMatchEvent(model);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao editar evento da partida: $e';
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
        title: const Text('Editar evento da partida'),
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
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _eventType,
              decoration: const InputDecoration(
                labelText: 'Evento',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'suspension_2min',
                  child: Text('2 minutos'),
                ),
                DropdownMenuItem(
                  value: 'yellow_card',
                  child: Text('Amarelo'),
                ),
                DropdownMenuItem(
                  value: 'red_card',
                  child: Text('Vermelho'),
                ),
                DropdownMenuItem(
                  value: 'blue_card',
                  child: Text('Azul'),
                ),
                DropdownMenuItem(
                  value: 'timeout',
                  child: Text('Timeout'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _eventType = value!;
                  if (!_needsPlayer) {
                    _playerId = null;
                  }
                });
              },
            ),
            if (_needsPlayer) ...[
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
            ],
            const SizedBox(height: 12),
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