import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/goal_zone_breakdown_model.dart';
import '../../repositories/goal_zone_breakdown_repository.dart';

class GoalZoneBreakdownTestPage extends StatefulWidget {
  const GoalZoneBreakdownTestPage({super.key});

  @override
  State<GoalZoneBreakdownTestPage> createState() =>
      _GoalZoneBreakdownTestPageState();
}

class _GoalZoneBreakdownTestPageState
    extends State<GoalZoneBreakdownTestPage> {
  final _supabase = Supabase.instance.client;
  final _repository = GoalZoneBreakdownRepository();

  bool _isLoading = true;
  bool _isLoadingBreakdown = false;

  String _selectedType = 'player';
  int _selectedShotZoneId = 9;

  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _goalkeepers = [];
  String? _selectedPlayerId;
  String? _selectedGoalkeeperId;

  List<GoalZoneBreakdownModel> _breakdown = [];

  final List<Map<String, dynamic>> _shotZones = const [
    {'id': 1, 'label': 'Z01'},
    {'id': 2, 'label': 'Z02'},
    {'id': 3, 'label': 'Z03'},
    {'id': 4, 'label': 'Z04'},
    {'id': 5, 'label': 'Z05'},
    {'id': 6, 'label': 'Z06'},
    {'id': 7, 'label': 'Z07'},
    {'id': 8, 'label': 'Z08'},
    {'id': 9, 'label': 'Z09'},
    {'id': 10, 'label': 'Z10'},
    {'id': 11, 'label': '7M'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  Future<void> _loadAthletes() async {
    try {
      final playersResponse = await _supabase
          .from('players')
          .select('id, full_name')
          .order('full_name', ascending: true);

      final goalkeepersResponse = await _supabase
          .from('match_players')
          .select('player_id, players(id, full_name)')
          .eq('is_goalkeeper', true);

      final players = (playersResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final gkMap = <String, Map<String, dynamic>>{};
      for (final row in (goalkeepersResponse as List)) {
        final item = Map<String, dynamic>.from(row as Map);
        final player = item['players'];
        if (player != null) {
          final p = Map<String, dynamic>.from(player as Map);
          gkMap[p['id'] as String] = {
            'id': p['id'],
            'full_name': p['full_name'],
          };
        }
      }

      final goalkeepers = gkMap.values.toList()
        ..sort((a, b) =>
            (a['full_name'] as String).compareTo(b['full_name'] as String));

      setState(() {
        _players = players;
        _goalkeepers = goalkeepers;
        _selectedPlayerId = players.isNotEmpty ? players.first['id'] as String : null;
        _selectedGoalkeeperId =
            goalkeepers.isNotEmpty ? goalkeepers.first['id'] as String : null;
        _isLoading = false;
      });

      await _loadBreakdown();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar atletas: $e')),
      );
    }
  }

  Future<void> _loadBreakdown() async {
    setState(() {
      _isLoadingBreakdown = true;
    });

    try {
      List<GoalZoneBreakdownModel> data = [];

      if (_selectedType == 'player' && _selectedPlayerId != null) {
        data = await _repository.getPlayerBreakdown(
          playerId: _selectedPlayerId!,
          shotZoneId: _selectedShotZoneId,
        );
      }

      if (_selectedType == 'goalkeeper' && _selectedGoalkeeperId != null) {
        data = await _repository.getGoalkeeperBreakdown(
          goalkeeperId: _selectedGoalkeeperId!,
          shotZoneId: _selectedShotZoneId,
        );
      }

      setState(() {
        _breakdown = data;
        _isLoadingBreakdown = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBreakdown = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar breakdown: $e')),
      );
    }
  }

  String _goalZoneLabel(int id) => 'G${id.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Zona → Gol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'player', child: Text('Jogador')),
                DropdownMenuItem(value: 'goalkeeper', child: Text('Goleiro')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                setState(() {
                  _selectedType = value;
                });
                await _loadBreakdown();
              },
            ),
            const SizedBox(height: 12),
            if (_selectedType == 'player')
              DropdownButtonFormField<String>(
                initialValue: _selectedPlayerId,
                decoration: const InputDecoration(
                  labelText: 'Jogador',
                  border: OutlineInputBorder(),
                ),
                items: _players
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e['id'] as String,
                        child: Text(e['full_name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  setState(() {
                    _selectedPlayerId = value;
                  });
                  await _loadBreakdown();
                },
              ),
            if (_selectedType == 'goalkeeper')
              DropdownButtonFormField<String>(
                initialValue: _selectedGoalkeeperId,
                decoration: const InputDecoration(
                  labelText: 'Goleiro',
                  border: OutlineInputBorder(),
                ),
                items: _goalkeepers
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e['id'] as String,
                        child: Text(e['full_name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  setState(() {
                    _selectedGoalkeeperId = value;
                  });
                  await _loadBreakdown();
                },
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedShotZoneId,
              decoration: const InputDecoration(
                labelText: 'Zona de chute',
                border: OutlineInputBorder(),
              ),
              items: _shotZones
                  .map(
                    (e) => DropdownMenuItem<int>(
                      value: e['id'] as int,
                      child: Text(e['label'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                setState(() {
                  _selectedShotZoneId = value;
                });
                await _loadBreakdown();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoadingBreakdown
                  ? const Center(child: CircularProgressIndicator())
                  : _breakdown.isEmpty
                      ? const Center(
                          child: Text('Nenhum dado encontrado para esse filtro.'),
                        )
                      : ListView.separated(
                          itemCount: _breakdown.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _breakdown[index];

                            return Card(
                              child: ListTile(
                                title: Text(_goalZoneLabel(item.goalZoneId)),
                                subtitle: Text(
                                  _selectedType == 'player'
                                      ? 'Chutes: ${item.totalShots} | Gols: ${item.totalGoals}'
                                      : 'Chutes sofridos: ${item.totalShots} | Defesas: ${item.totalSaves}',
                                ),
                                trailing: Text(
                                  '${item.percentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}