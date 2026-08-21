import 'package:flutter/material.dart';

import '../../repositories/standalone_scout_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import 'standalone_match_statistics_detail_page.dart';

class StandaloneMatchStatisticsListPage extends StatefulWidget {
  const StandaloneMatchStatisticsListPage({super.key});

  @override
  State<StandaloneMatchStatisticsListPage> createState() =>
      _StandaloneMatchStatisticsListPageState();
}

class _StandaloneMatchStatisticsListPageState
    extends State<StandaloneMatchStatisticsListPage> {
  final _repository = StandaloneScoutRepository();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allMatches = [];
  List<Map<String, dynamic>> _filteredMatches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await _repository.getMatches();

      if (!mounted) return;

      setState(() {
        _allMatches = matches;
        _filteredMatches = matches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar partidas avulsas: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredMatches = _allMatches;
        return;
      }

      _filteredMatches = _allMatches.where((match) {
        final homeName =
            (match['home_team_name'] as String? ?? '').toLowerCase();
        final awayName =
            (match['away_team_name'] as String? ?? '').toLowerCase();
        return homeName.contains(query) || awayName.contains(query);
      }).toList();
    });
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Sem data';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Sem data';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'finished':
        return 'Finalizada';
      case 'cancelled':
        return 'Cancelada';
      case 'in_progress':
      default:
        return 'Em andamento';
    }
  }

  Widget _buildTeamIcon() {
    return const SizedBox(
      width: 52,
      height: 52,
      child: CircleAvatar(
        backgroundColor: AppThemeColors.primarySoft,
        foregroundColor: AppThemeColors.primary,
        child: Icon(Icons.sports_handball),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final homeName = match['home_team_name'] as String? ?? 'Time A';
    final awayName = match['away_team_name'] as String? ?? 'Time B';
    final homeScore = match['home_score'] as int? ?? 0;
    final awayScore = match['away_score'] as int? ?? 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StandaloneMatchStatisticsDetailPage(match: match),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Partida avulsa',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(_statusLabel(match['status'] as String?)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(match['created_at']),
                style: const TextStyle(
                  color: AppThemeColors.slate,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildTeamIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      homeName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '$homeScore x $awayScore',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      awayName,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildTeamIcon(),
                ],
              ),
            ],
          ),
        ),
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
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Pesquisar por time',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _filteredMatches.isEmpty
                            ? const Center(
                                child:
                                    Text('Nenhuma partida avulsa encontrada.'),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _filteredMatches.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildMatchCard(
                                      _filteredMatches[index],
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
