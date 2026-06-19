import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/match_model.dart';
import '../../models/match_player_model.dart';
import '../../repositories/match_player_repository.dart';

class MatchPlayerFormPage extends StatefulWidget {
  final MatchModel match;
  final String teamId;
  final MatchPlayerModel? matchPlayer;

  const MatchPlayerFormPage({
    super.key,
    required this.match,
    required this.teamId,
    this.matchPlayer,
  });

  @override
  State<MatchPlayerFormPage> createState() => _MatchPlayerFormPageState();
}

class _MatchPlayerFormPageState extends State<MatchPlayerFormPage> {
  final _repository = MatchPlayerRepository();
  final _supabase = Supabase.instance.client;

  final _playerSearchController = TextEditingController();
  final _shirtNumberController = TextEditingController();

  List<Map<String, dynamic>> _players = [];
  String? _playerId;
  String _positionInMatch = 'nao_informado';
  bool _isGoalkeeper = false;
  bool _isActiveInMatch = true;

  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  bool _isUsingFallbackPlayers = false;

  bool get isEditing => widget.matchPlayer != null;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    try {
      final existingMatchPlayersResponse = await _supabase
          .from('match_players')
          .select('player_id')
          .eq('match_id', widget.match.id)
          .eq('team_id', widget.teamId);

      final existingPlayerIds = (existingMatchPlayersResponse as List)
          .map((item) => item['player_id'] as String)
          .toSet();

      if (widget.matchPlayer != null) {
        existingPlayerIds.remove(widget.matchPlayer!.playerId);
      }

      final players = <Map<String, dynamic>>[];
      var isUsingFallbackPlayers = false;
      try {
        final teamPlayersResponse = await _supabase
            .from('team_players')
            .select('player_id, players(id, full_name, primary_position)')
            .eq('team_id', widget.teamId)
            .eq('is_active', true);

        for (final item in teamPlayersResponse as List) {
          final player = item['players'];
          final playerId = item['player_id'] as String?;
          if (player == null || playerId == null || existingPlayerIds.contains(playerId)) {
            continue;
          }

          players.add({
            'id': player['id'],
            'full_name': player['full_name'],
            'primary_position': player['primary_position'],
          });
        }
      } catch (_) {
        isUsingFallbackPlayers = true;
      }

      if (players.isEmpty) {
        final allPlayersResponse = await _supabase
            .from('players')
            .select('id, full_name, primary_position')
            .eq('is_active', true)
            .order('full_name', ascending: true);

        isUsingFallbackPlayers = true;

        for (final item in allPlayersResponse as List) {
          final playerId = item['id'] as String?;
          if (playerId == null || existingPlayerIds.contains(playerId)) {
            continue;
          }

          players.add({
            'id': playerId,
            'full_name': item['full_name'],
            'primary_position': item['primary_position'],
          });
        }
      }

      final item = widget.matchPlayer;
      String? currentPlayerName;
      if (item != null) {
        _playerId = item.playerId;
        _shirtNumberController.text = item.shirtNumber?.toString() ?? '';
        _positionInMatch = item.positionInMatch;
        _isGoalkeeper = item.isGoalkeeper;
        _isActiveInMatch = item.isActiveInMatch;

        final hasCurrentPlayer = players.any(
          (player) => player['id'] == item.playerId,
        );

        if (!hasCurrentPlayer) {
          final currentPlayerResponse = await _supabase
              .from('players')
              .select('id, full_name, primary_position')
              .eq('id', item.playerId)
              .maybeSingle();

          if (currentPlayerResponse != null) {
            players.add({
              'id': currentPlayerResponse['id'],
              'full_name': currentPlayerResponse['full_name'],
              'primary_position': currentPlayerResponse['primary_position'],
            });
          }
        }

        currentPlayerName = _findPlayerNameById(players, item.playerId);
      }

      players.sort(
        (a, b) => (a['full_name'] as String).compareTo(b['full_name'] as String),
      );

      if (!mounted) return;

      setState(() {
        _players = players;
        _isUsingFallbackPlayers = isUsingFallbackPlayers;
        _isInitialLoading = false;
      });

      if (item != null) {
        _playerSearchController.text = currentPlayerName ?? '';
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar jogadores do time: $e';
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_playerId == null) {
      setState(() {
        _errorMessage = 'Selecione um jogador.';
      });
      return;
    }

    final shirtNumber = _shirtNumberController.text.trim().isEmpty
        ? null
        : int.tryParse(_shirtNumberController.text.trim());

    if (_shirtNumberController.text.trim().isNotEmpty && shirtNumber == null) {
      setState(() {
        _errorMessage = 'Numero da camisa invalido.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final model = MatchPlayerModel(
        id: widget.matchPlayer?.id ?? '',
        matchId: widget.match.id,
        teamId: widget.teamId,
        playerId: _playerId!,
        shirtNumber: shirtNumber,
        isGoalkeeper: _isGoalkeeper,
        positionInMatch: _positionInMatch,
        isActiveInMatch: _isActiveInMatch,
      );

      if (isEditing) {
        await _repository.updateMatchPlayer(model);
      } else {
        await _repository.createMatchPlayer(model);
      }

      if (!mounted) return;

      if (isEditing) {
        Navigator.of(context).pop();
        return;
      }

      final addedPlayerName = _selectedPlayerName ?? 'Jogador';
      await _loadPlayers();

      if (!mounted) return;

      _playerSearchController.clear();
      _shirtNumberController.clear();

      setState(() {
        _playerId = null;
        _positionInMatch = 'nao_informado';
        _isGoalkeeper = false;
        _isActiveInMatch = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$addedPlayerName adicionado. Voce pode continuar escalando o elenco.',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar jogador da partida: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _findPlayerNameById(
    List<Map<String, dynamic>> players,
    String? playerId,
  ) {
    if (playerId == null) return null;

    for (final player in players) {
      if (player['id'] == playerId) {
        return player['full_name'] as String?;
      }
    }

    return null;
  }

  String? get _selectedPlayerName => _findPlayerNameById(_players, _playerId);

  String _normalizedPosition(String? value) {
    if (value == null || value.trim().isEmpty) return 'nao_informado';
    return value.trim();
  }

  String _findPlayerPrimaryPosition(String? playerId) {
    if (playerId == null) return 'nao_informado';

    for (final player in _players) {
      if (player['id'] == playerId) {
        return _normalizedPosition(player['primary_position'] as String?);
      }
    }

    return 'nao_informado';
  }

  void _applySelectedPlayer(String? playerId, String playerName) {
    setState(() {
      _playerId = playerId;
      _playerSearchController.text = playerName;
      _positionInMatch = _findPlayerPrimaryPosition(playerId);
      _errorMessage = null;
    });
  }

  List<Map<String, dynamic>> get _filteredPlayers {
    final query = _playerSearchController.text.trim().toLowerCase();

    final items = _players.where((player) {
      final name = (player['full_name'] as String? ?? '').toLowerCase();
      if (query.isEmpty) return true;
      return name.contains(query);
    }).toList();

    return items.take(8).toList();
  }

  bool get _showSuggestions {
    if (isEditing || _players.isEmpty) return false;

    final selectedName = _selectedPlayerName;
    if (_playerId == null || selectedName == null) return true;

    return _playerSearchController.text.trim().toLowerCase() !=
        selectedName.toLowerCase();
  }

  Widget _buildPlayerSelector() {
    if (isEditing) {
      return TextField(
        controller: _playerSearchController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Jogador',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person_search_outlined),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _playerSearchController,
          onChanged: (value) {
            setState(() {
              if (_selectedPlayerName != null &&
                  value.trim().toLowerCase() !=
                      _selectedPlayerName!.trim().toLowerCase()) {
                _playerId = null;
              }
            });
          },
          decoration: const InputDecoration(
            labelText: 'Buscar jogador por nome',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
        ),
        if (_selectedPlayerName != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Selecionado: $_selectedPlayerName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _playerId = null;
                      _playerSearchController.clear();
                    });
                  },
                  child: const Text('Trocar'),
                ),
              ],
            ),
          ),
        ],
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: _filteredPlayers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Nenhum jogador encontrado para essa busca.'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredPlayers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final player = _filteredPlayers[index];
                      final playerName = player['full_name'] as String? ?? 'Jogador';

                      return ListTile(
                        dense: true,
                        title: Text(playerName),
                        onTap: () {
                          _applySelectedPlayer(
                            player['id'] as String?,
                            playerName,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _playerSearchController.dispose();
    _shirtNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar atleta da partida' : 'Adicionar atleta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPlayerSelector(),
            if (_isUsingFallbackPlayers) ...[
              const SizedBox(height: 8),
              const Text(
                'Esse time ainda não tem elenco vinculado. Por enquanto, estamos exibindo todos os jogadores ativos cadastrados.',
                textAlign: TextAlign.center,
              ),
            ],
            if (_players.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Nenhum jogador disponível para adicionar nesta partida.',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _shirtNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número da camisa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _positionInMatch,
              decoration: const InputDecoration(
                labelText: 'Posição na partida',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'goleiro', child: Text('Goleiro')),
                DropdownMenuItem(value: 'ponta_esquerda', child: Text('Ponta esquerda')),
                DropdownMenuItem(value: 'armador_esquerdo', child: Text('Armador esquerdo')),
                DropdownMenuItem(value: 'armador_central', child: Text('Armador central')),
                DropdownMenuItem(value: 'armador_direito', child: Text('Armador direito')),
                DropdownMenuItem(value: 'ponta_direita', child: Text('Ponta direita')),
                DropdownMenuItem(value: 'pivo', child: Text('Pivô')),
                DropdownMenuItem(value: 'nao_informado', child: Text('Não informado')),
              ],
              onChanged: (value) {
                setState(() {
                  _positionInMatch = value ?? 'nao_informado';
                });
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isGoalkeeper,
              title: const Text('É goleiro'),
              onChanged: (value) {
                setState(() {
                  _isGoalkeeper = value;
                });
              },
            ),
            SwitchListTile(
              value: _isActiveInMatch,
              title: const Text('Ativo para a partida'),
              onChanged: (value) {
                setState(() {
                  _isActiveInMatch = value;
                });
              },
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
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        isEditing
                            ? 'Salvar alterações'
                            : 'Salvar e continuar',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
