import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/match_model.dart';
import '../../repositories/match_repository.dart';
import 'live_scout_page.dart';

class ScoutMatchListPage extends StatefulWidget {
  const ScoutMatchListPage({super.key});

  @override
  State<ScoutMatchListPage> createState() => _ScoutMatchListPageState();
}

class _ScoutMatchListPageState extends State<ScoutMatchListPage> {
  final _repository = MatchRepository();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  List<MatchModel> _matches = [];

  Map<String, String> _competitionNames = {};
  Map<String, String> _teamNames = {};
  Map<String, String?> _teamShields = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final matches = await _repository.getMatches();

      final competitionsResponse = await _supabase
          .from('competitions')
          .select('id, name');

      final teamsResponse = await _supabase
          .from('teams')
          .select('id, name, shield_url');

      final competitionMap = <String, String>{};
      for (final item in competitionsResponse) {
        competitionMap[item['id'] as String] = item['name'] as String;
      }

      final teamMap = <String, String>{};
      final shieldMap = <String, String?>{};
      for (final item in teamsResponse) {
        teamMap[item['id'] as String] = item['name'] as String;
        shieldMap[item['id'] as String] = item['shield_url'] as String?;
      }

      if (!mounted) return;

      setState(() {
        _matches = matches;
        _competitionNames = competitionMap;
        _teamNames = teamMap;
        _teamShields = shieldMap;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar partidas: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _competitionLabel(String id) => _competitionNames[id] ?? id;
  String _teamLabel(String id) => _teamNames[id] ?? id;
  String? _teamShield(String id) => _teamShields[id];

  Widget _shield(String? url) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.shield_outlined, size: 28);
    }

    return Image.network(
      url,
      width: 28,
      height: 28,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidas para Scout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _matches.isEmpty
                  ? const Center(child: Text('Nenhuma partida encontrada.'))
                  : ListView.builder(
                      itemCount: _matches.length,
                      itemBuilder: (context, index) {
                        final item = _matches[index];

                        return ListTile(
                          title: Row(
                            children: [
                              _shield(_teamShield(item.homeTeamId)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _teamLabel(item.homeTeamId),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'x',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _teamLabel(item.awayTeamId),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _shield(_teamShield(item.awayTeamId)),
                            ],
                          ),
                          subtitle: Text(
                            '${_competitionLabel(item.competitionId)}\n'
                            'Status: ${item.status} | Scout: ${item.scoutStatus}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LiveScoutPage(match: item),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
