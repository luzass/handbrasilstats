import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/match_model.dart';
import '../../models/match_player_model.dart';
import '../../models/match_roster_load_result.dart';
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
  bool _isSyncingRoster = false;
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

  Future<bool?> _showRosterLoadModeDialog({
    required String title,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: const Text(
            'Deseja adicionar apenas quem ainda nao esta na partida ou substituir o elenco atual desse time?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Adicionar so os que faltam'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Substituir elenco atual'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadRosterForTeam({
    required String teamId,
    required String teamName,
  }) async {
    final replaceExisting = await _showRosterLoadModeDialog(
      title: 'Carregar elenco de $teamName',
    );

    if (replaceExisting == null) {
      return;
    }

    setState(() {
      _isSyncingRoster = true;
      _errorMessage = null;
    });

    try {
      final result = await _repository.loadRosterFromTeam(
        matchId: widget.match.id,
        teamId: teamId,
        replaceExisting: replaceExisting,
      );

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      _showRosterLoadSnackBar(
        teamName: teamName,
        result: result,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar elenco do time: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingRoster = false;
        });
      }
    }
  }

  Future<void> _loadBothRosters() async {
    final replaceExisting = await _showRosterLoadModeDialog(
      title: 'Carregar os dois elencos',
    );

    if (replaceExisting == null) {
      return;
    }

    setState(() {
      _isSyncingRoster = true;
      _errorMessage = null;
    });

    try {
      final homeResult = await _repository.loadRosterFromTeam(
        matchId: widget.match.id,
        teamId: widget.match.homeTeamId,
        replaceExisting: replaceExisting,
      );

      final awayResult = await _repository.loadRosterFromTeam(
        matchId: widget.match.id,
        teamId: widget.match.awayTeamId,
        replaceExisting: replaceExisting,
      );

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      final added = homeResult.addedCount + awayResult.addedCount;
      final skipped = homeResult.skippedCount + awayResult.skippedCount;
      final removed = homeResult.removedCount + awayResult.removedCount;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Elencos carregados. Adicionados: $added | Ignorados: $skipped | Removidos: $removed',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar os elencos: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingRoster = false;
        });
      }
    }
  }

  void _showRosterLoadSnackBar({
    required String teamName,
    required MatchRosterLoadResult result,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$teamName: adicionados ${result.addedCount}, ignorados ${result.skippedCount}, removidos ${result.removedCount}.',
        ),
      ),
    );
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
        actions: [
          IconButton(
            onPressed: _isSyncingRoster ? null : _loadBothRosters,
            tooltip: 'Carregar elenco dos dois times',
            icon: _isSyncingRoster
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check_circle_outlined),
          ),
        ],
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
                IconButton(
                  onPressed: _isSyncingRoster
                      ? null
                      : () => _loadRosterForTeam(
                            teamId: teamId,
                            teamName: title,
                          ),
                  tooltip: 'Carregar elenco base do time',
                  icon: const Icon(Icons.download_for_offline_outlined),
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
