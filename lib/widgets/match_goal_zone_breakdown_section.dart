import 'package:flutter/material.dart';

import '../models/match_goal_zone_breakdown_model.dart';
import '../repositories/match_goal_zone_breakdown_repository.dart';
import 'goal_zone_heatmap_widget.dart';

class MatchGoalZoneBreakdownSection extends StatefulWidget {
  final String matchId;
  final String athleteId;
  final bool isGoalkeeper;
  final String title;

  const MatchGoalZoneBreakdownSection({
    super.key,
    required this.matchId,
    required this.athleteId,
    required this.isGoalkeeper,
    required this.title,
  });

  @override
  State<MatchGoalZoneBreakdownSection> createState() =>
      _MatchGoalZoneBreakdownSectionState();
}

class _MatchGoalZoneBreakdownSectionState
    extends State<MatchGoalZoneBreakdownSection> {
  final _repository = MatchGoalZoneBreakdownRepository();

  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedShotZoneId;
  List<MatchGoalZoneBreakdownModel> _breakdown = [];

  final List<Map<String, dynamic>> _shotZones = const [
    {'id': null, 'label': 'Geral'},
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
    _loadBreakdown();
  }

  Future<void> _loadBreakdown() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<MatchGoalZoneBreakdownModel> data;

      if (widget.isGoalkeeper) {
        data = await _repository.getGoalkeeperBreakdown(
          matchId: widget.matchId,
          goalkeeperId: widget.athleteId,
          shotZoneId: _selectedShotZoneId,
        );
      } else {
        data = await _repository.getPlayerBreakdown(
          matchId: widget.matchId,
          playerId: widget.athleteId,
          shotZoneId: _selectedShotZoneId,
        );
      }

      if (!mounted) return;

      setState(() {
        _breakdown = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar mapa do gol: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
            widget.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _selectedShotZoneId,
            decoration: const InputDecoration(
              labelText: 'Zona de chute',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _shotZones
                .map(
                  (e) => DropdownMenuItem<int?>(
                    value: e['id'] as int?,
                    child: Text(e['label'] as String),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              setState(() {
                _selectedShotZoneId = value;
              });
              await _loadBreakdown();
            },
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Text(_errorMessage!)
          else if (_breakdown.isEmpty)
            const Text('Nenhum dado encontrado para este filtro.')
          else ...[
            GoalZoneHeatmapWidget(
              breakdown: _breakdown,
              isGoalkeeper: widget.isGoalkeeper,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildLegendItem(Colors.white, 'Sem dados'),
                _buildLegendItem(Colors.green.shade300, '80%+'),
                _buildLegendItem(Colors.green.shade200, '60%+'),
                _buildLegendItem(Colors.yellow.shade200, '40%+'),
                _buildLegendItem(Colors.orange.shade200, '20%+'),
                _buildLegendItem(Colors.red.shade200, 'Abaixo de 20%'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}