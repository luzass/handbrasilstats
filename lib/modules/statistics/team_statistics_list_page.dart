import 'package:flutter/material.dart';

import '../../repositories/team_statistics_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import 'team_statistics_detail_page.dart';

class TeamStatisticsListPage extends StatefulWidget {
  const TeamStatisticsListPage({super.key});

  @override
  State<TeamStatisticsListPage> createState() => _TeamStatisticsListPageState();
}

class _TeamStatisticsListPageState extends State<TeamStatisticsListPage> {
  final _repository = TeamStatisticsRepository();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _filteredTeams = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _repository.getTeams();

      if (!mounted) return;

      setState(() {
        _teams = teams;
        _filteredTeams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar times: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredTeams = _teams;
      } else {
        _filteredTeams = _teams.where((team) {
          final name = (team['name'] as String? ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  Widget _buildShield(String? url) {
    return SizedBox(
      width: 58,
      height: 58,
      child: url == null || url.isEmpty
          ? const Icon(
              Icons.shield_outlined,
              size: 38,
              color: AppThemeColors.primary,
            )
          : Image.network(
              url,
              width: 58,
              height: 58,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.shield_outlined,
                  size: 38,
                  color: AppThemeColors.primary,
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatisticas dos Times'),
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
                            labelText: 'Procurar time',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _filteredTeams.isEmpty
                            ? const Center(child: Text('Nenhum time encontrado.'))
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _filteredTeams.length,
                                itemBuilder: (context, index) {
                                  final team = _filteredTeams[index];

                                  return Card(
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      leading: _buildShield(
                                        team['shield_url'] as String?,
                                      ),
                                      title: Text(
                                        team['name'] as String? ?? 'Time',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      trailing:
                                          const Icon(Icons.chevron_right_rounded),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TeamStatisticsDetailPage(
                                              teamId: team['id'] as String,
                                              teamName:
                                                  team['name'] as String? ??
                                                      'Time',
                                              shieldUrl:
                                                  team['shield_url'] as String?,
                                            ),
                                          ),
                                        );
                                      },
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
