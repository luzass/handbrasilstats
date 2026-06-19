import 'package:flutter/material.dart';

import '../../models/match_statistics_list_item_model.dart';
import '../../repositories/match_statistics_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import 'match_statistics_detail_page.dart';

class MatchStatisticsListPage extends StatefulWidget {
  const MatchStatisticsListPage({super.key});

  @override
  State<MatchStatisticsListPage> createState() =>
      _MatchStatisticsListPageState();
}

class _MatchStatisticsListPageState extends State<MatchStatisticsListPage> {
  final _repository = MatchStatisticsRepository();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<MatchStatisticsListItemModel> _allMatches = [];
  List<MatchStatisticsListItemModel> _filteredMatches = [];

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
      setState(() {
        _errorMessage = 'Erro ao carregar partidas: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredMatches = _allMatches;
      } else {
        _filteredMatches = _allMatches.where((match) {
          return match.homeTeamName.toLowerCase().contains(query) ||
              match.awayTeamName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Widget _buildShield(String? url) {
    return SizedBox(
      width: 56,
      height: 56,
      child: url == null || url.isEmpty
          ? const Icon(
              Icons.shield_outlined,
              size: 34,
              color: AppThemeColors.primary,
            )
          : Image.network(
              url,
              height: 56,
              width: 56,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.shield_outlined,
                  size: 34,
                  color: AppThemeColors.primary,
                );
              },
            ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sem data';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Widget _buildMatchCard(MatchStatisticsListItemModel match) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MatchStatisticsDetailPage(match: match),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.competitionName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(match.matchDate),
                style: const TextStyle(
                  color: AppThemeColors.slate,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildShield(match.homeTeamShieldUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      match.homeTeamName,
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
                      '${match.scoreHome} x ${match.scoreAway}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.awayTeamName,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildShield(match.awayTeamShieldUrl),
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
        title: const Text('Estatisticas das Partidas'),
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
                                child: Text('Nenhuma partida encontrada.'),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _filteredMatches.length,
                                itemBuilder: (context, index) {
                                  return _buildMatchCard(
                                    _filteredMatches[index],
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
