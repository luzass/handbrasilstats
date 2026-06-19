import 'package:flutter/material.dart';

import '../../models/player_model.dart';
import '../../repositories/player_repository.dart';
import 'player_form_page.dart';

class PlayerListPage extends StatefulWidget {
  const PlayerListPage({super.key});

  @override
  State<PlayerListPage> createState() => _PlayerListPageState();
}

class _PlayerListPageState extends State<PlayerListPage> {
  final _repository = PlayerRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<PlayerModel> _players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.getPlayers();

      if (!mounted) return;

      setState(() {
        _players = items;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar jogadores: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openForm([PlayerModel? player]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerFormPage(player: player),
      ),
    );

    await _loadPlayers();
  }

  Widget _buildPlayerAvatar(PlayerModel player) {
    if (player.photoUrl != null && player.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        foregroundImage: NetworkImage(player.photoUrl!),
        onForegroundImageError: (_, __) {},
        child: const Icon(Icons.person_outline),
      );
    }

    return const CircleAvatar(
      child: Icon(Icons.person_outline),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jogadores'),
        actions: [
          IconButton(
            onPressed: () => _openForm(),
            tooltip: 'Adicionar jogador',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _players.isEmpty
                  ? const Center(child: Text('Nenhum jogador cadastrado.'))
                  : ListView.builder(
                      itemCount: _players.length,
                      itemBuilder: (context, index) {
                        final item = _players[index];

                        return ListTile(
                          leading: _buildPlayerAvatar(item),
                          title: Text(item.fullName),
                          subtitle: Text(
                            '${item.primaryPosition} | ${item.birthCity ?? '-'} | CPF: ${item.cpf ?? '-'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openForm(item),
                          ),
                        );
                      },
                    ),
    );
  }
}
