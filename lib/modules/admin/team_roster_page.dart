import 'package:flutter/material.dart';

import '../../models/player_model.dart';
import '../../models/team_model.dart';
import '../../repositories/player_repository.dart';
import '../../repositories/team_roster_repository.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/athlete_photo_avatar.dart';

class TeamRosterPage extends StatefulWidget {
  final TeamModel team;

  const TeamRosterPage({
    super.key,
    required this.team,
  });

  @override
  State<TeamRosterPage> createState() => _TeamRosterPageState();
}

class _TeamRosterPageState extends State<TeamRosterPage> {
  final _playerRepository = PlayerRepository();
  final _rosterRepository = TeamRosterRepository();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<PlayerModel> _allPlayers = [];
  Set<String> _activeRosterIds = <String>{};
  String _search = '';

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
      final results = await Future.wait([
        _playerRepository.getPlayers(),
        _rosterRepository.getActivePlayerIds(widget.team.id),
      ]);

      if (!mounted) return;

      setState(() {
        _allPlayers = (results[0] as List<PlayerModel>)
            .where((player) => player.isActive)
            .toList();
        _activeRosterIds = results[1] as Set<String>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar elenco do time: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlayer({
    required PlayerModel player,
    required bool shouldBeActive,
  }) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (shouldBeActive) {
        await _rosterRepository.addPlayerToTeam(
          teamId: widget.team.id,
          playerId: player.id,
        );
      } else {
        await _rosterRepository.removePlayerFromTeam(
          teamId: widget.team.id,
          playerId: player.id,
        );
      }

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao atualizar elenco: $e';
        _isSaving = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool _matchesSearch(PlayerModel player) {
    final normalized = _search.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    return player.fullName.toLowerCase().contains(normalized) ||
        ((player.cpf ?? '').toLowerCase().contains(normalized)) ||
        (player.primaryPosition.toLowerCase().contains(normalized)) ||
        ((player.birthCity ?? '').toLowerCase().contains(normalized));
  }

  List<PlayerModel> get _rosterPlayers {
    final items = _allPlayers
        .where((player) => _activeRosterIds.contains(player.id))
        .where(_matchesSearch)
        .toList();

    items.sort((a, b) => a.fullName.compareTo(b.fullName));
    return items;
  }

  List<PlayerModel> get _availablePlayers {
    final items = _allPlayers
        .where((player) => !_activeRosterIds.contains(player.id))
        .where(_matchesSearch)
        .toList();

    items.sort((a, b) => a.fullName.compareTo(b.fullName));
    return items;
  }

  Widget _buildPlayerTile({
    required PlayerModel player,
    required bool isInRoster,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2DD)),
      ),
      child: Row(
        children: [
          AthletePhotoAvatar(
            photoUrl: player.photoUrl,
            size: 52,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${player.primaryPosition} | CPF: ${player.cpf ?? '-'} | ${player.birthCity ?? '-'}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSaving
                ? null
                : () => _togglePlayer(
                      player: player,
                      shouldBeActive: !isInRoster,
                    ),
            icon: Icon(
              isInRoster ? Icons.remove_circle_outline : Icons.add_circle_outline,
            ),
            tooltip: isInRoster ? 'Remover do elenco' : 'Adicionar ao elenco',
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String emptyText,
    required List<PlayerModel> players,
    required bool isInRoster,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${players.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (players.isEmpty)
              Text(emptyText)
            else
              ...players.map(
                (player) => _buildPlayerTile(
                  player: player,
                  isInRoster: isInRoster,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Elenco - ${widget.team.name}'),
      ),
      body: AppBackdrop(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _search = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Buscar por nome ou CPF',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'Elenco do time',
                          emptyText: 'Nenhum jogador no elenco desse time.',
                          players: _rosterPlayers,
                          isInRoster: true,
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'Jogadores disponíveis',
                          emptyText: 'Nenhum jogador disponível para adicionar.',
                          players: _availablePlayers,
                          isInRoster: false,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
