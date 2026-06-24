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
  final Map<String, TextEditingController> _shirtNumberControllers = {};

  bool _isLoading = true;
  bool _isSyncingRoster = false;
  bool _isSavingShirtNumbers = false;
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

      final playersResponse = await _supabase.from('players').select('id, full_name');

      final teamsResponse = await _supabase.from('teams').select('id, name');

      final playerMap = <String, String>{};
      for (final item in playersResponse) {
        playerMap[item['id'] as String] = item['full_name'] as String;
      }

      final teamMap = <String, String>{};
      for (final item in teamsResponse) {
        teamMap[item['id'] as String] = item['name'] as String;
      }

      _replaceShirtNumberControllers(matchPlayers);

      if (!mounted) return;

      setState(() {
        _items = matchPlayers;
        _playerNames = playerMap;
        _teamNames = teamMap;
      });
    } catch (e) {
      if (!mounted) return;

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

  void _replaceShirtNumberControllers(List<MatchPlayerModel> items) {
    for (final controller in _shirtNumberControllers.values) {
      controller.dispose();
    }
    _shirtNumberControllers.clear();

    for (final item in items) {
      _shirtNumberControllers[item.id] = TextEditingController(
        text: item.shirtNumber?.toString() ?? '',
      );
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

  Future<void> _saveAllShirtNumbers() async {
    FocusScope.of(context).unfocus();

    final updates = <MatchPlayerModel>[];

    for (final item in _items) {
      final controller = _shirtNumberControllers[item.id];
      final rawValue = controller?.text.trim() ?? '';
      final shirtNumber = rawValue.isEmpty ? null : int.tryParse(rawValue);

      if (rawValue.isNotEmpty && shirtNumber == null) {
        setState(() {
          _errorMessage =
              'Preencha apenas numeros validos nas camisas antes de salvar.';
        });
        return;
      }

      if (shirtNumber != item.shirtNumber) {
        updates.add(
          MatchPlayerModel(
            id: item.id,
            matchId: item.matchId,
            teamId: item.teamId,
            playerId: item.playerId,
            shirtNumber: shirtNumber,
            isGoalkeeper: item.isGoalkeeper,
            positionInMatch: item.positionInMatch,
            isActiveInMatch: item.isActiveInMatch,
          ),
        );
      }
    }

    if (updates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma camisa foi alterada.'),
        ),
      );
      return;
    }

    setState(() {
      _isSavingShirtNumbers = true;
      _errorMessage = null;
    });

    try {
      await Future.wait(updates.map(_repository.updateMatchPlayer));

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${updates.length} camisa(s) salva(s) com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao salvar camisas: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingShirtNumbers = false;
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
            onPressed: _isSavingShirtNumbers || _isSyncingRoster
                ? null
                : _saveAllShirtNumbers,
            tooltip: 'Salvar todas as camisas',
            icon: _isSavingShirtNumbers
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  tooltip: 'Adicionar atleta',
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
            const Text(
              'Preencha as camisas ao lado dos nomes e salve tudo de uma vez no botao do topo.',
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('Nenhum atleta vinculado.')
            else
              ...items.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE1E6EB)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _playerNames[item.playerId] ?? item.playerId,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Posicao: ${item.positionInMatch} | '
                                'Goleiro: ${item.isGoalkeeper ? 'Sim' : 'Nao'} | '
                                'Ativo: ${item.isActiveInMatch ? 'Sim' : 'Nao'}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 96,
                          child: TextField(
                            controller: _shirtNumberControllers[item.id],
                            keyboardType: TextInputType.number,
                            enabled: !_isSavingShirtNumbers,
                            decoration: const InputDecoration(
                              labelText: 'Camisa',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Editar detalhes do atleta',
                          onPressed: () => _openForm(teamId, item),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _shirtNumberControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
