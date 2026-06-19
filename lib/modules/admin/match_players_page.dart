import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/match_model.dart';
import '../../models/match_player_model.dart';
import '../../repositories/match_player_repository.dart';
import 'match_player_form_page.dart';

class MatchPlayersPage extends StatefulWidget {
  final MatchModel match;

  const MatchPlayersPage({
    super.key,
    required this.match,
  });

  @override
  State<MatchPlayersPage> createState() => _MatchPlayersPageState();
}

class _MatchPlayersPageState extends State<MatchPlayersPage> {
  final _repository = MatchPlayerRepository();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  List<MatchPlayerModel> _items = [];
  Map<String, String> _playerNames = {};
  Map<String, String> _teamNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final matchPlayers = await _repository.getMatchPlayers(widget.match.id);

      final playersResponse = await _supabase
          .from('players')
          .select('id, full_name');

      final teamsResponse = await _supabase
          .from('teams')
          .select('id, name');

      final playerMap = <String, String>{};
      for (final item in playersResponse) {
        playerMap[item['id'] as String] = item['full_name'] as String;
      }

      final teamMap = <String, String>{};
      for (final item in teamsResponse) {
        teamMap[item['id'] as String] = item['name'] as String;
      }

      if (!mounted) return;

      setState(() {
        _items = matchPlayers;
        _playerNames = playerMap;
        _teamNames = teamMap;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar elenco da partida: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openForm(String teamId, [MatchPlayerModel? item]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchPlayerFormPage(
          match: widget.match,
          teamId: teamId,
          matchPlayer: item,
        ),
      ),
    );

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final homeTeamItems =
        _items.where((e) => e.teamId == widget.match.homeTeamId).toList();
    final awayTeamItems =
        _items.where((e) => e.teamId == widget.match.awayTeamId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elenco da partida'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTeamSection(
                      title: _teamNames[widget.match.homeTeamId] ?? 'Mandante',
                      teamId: widget.match.homeTeamId,
                      items: homeTeamItems,
                    ),
                    const SizedBox(height: 24),
                    _buildTeamSection(
                      title: _teamNames[widget.match.awayTeamId] ?? 'Visitante',
                      teamId: widget.match.awayTeamId,
                      items: awayTeamItems,
                    ),
                  ],
                ),
    );
  }

  Widget _buildTeamSection({
    required String title,
    required String teamId,
    required List<MatchPlayerModel> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _openForm(teamId),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('Nenhum atleta vinculado.')
            else
              ...items.map(
                (item) => ListTile(
                  title: Text(_playerNames[item.playerId] ?? item.playerId),
                  subtitle: Text(
                    'Camisa: ${item.shirtNumber ?? '-'} | '
                    'Posição: ${item.positionInMatch} | '
                    'Goleiro: ${item.isGoalkeeper ? 'Sim' : 'Não'} | '
                    'Ativo: ${item.isActiveInMatch ? 'Sim' : 'Não'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _openForm(teamId, item),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}