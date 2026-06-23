import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/player_csv_import_result.dart';
import '../../models/player_csv_import_row.dart';
import '../../models/player_model.dart';
import '../../models/team_model.dart';
import '../../repositories/player_repository.dart';
import '../../repositories/team_roster_repository.dart';
import '../../utils/csv_utils.dart';
import '../../utils/player_csv_import_parser.dart';
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
  bool _isImportingCsv = false;
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

  Future<void> _pickAndImportCsv() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _errorMessage = 'Nao foi possivel ler o CSV selecionado.';
        });
        return;
      }

      final csvContent = decodeCsvBytes(bytes);
      final rows = _parseImportRows(csvContent);
      if (rows.isEmpty) {
        setState(() {
          _errorMessage = 'O CSV nao possui jogadores validos para importar.';
        });
        return;
      }

      final shouldImport = await _showImportPreviewDialog(
        fileName: file.name,
        rows: rows,
      );

      if (shouldImport != true) {
        return;
      }

      setState(() {
        _isImportingCsv = true;
        _errorMessage = null;
      });

      final importResult = await _rosterRepository.importPlayersFromRows(
        teamId: widget.team.id,
        rows: rows,
      );

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      await _showImportResultDialog(importResult);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao importar CSV: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isImportingCsv = false;
        });
      }
    }
  }

  List<PlayerCsvImportRow> _parseImportRows(String csvContent) {
    return parsePlayerCsvImportRows(csvContent);
  }

  Future<bool?> _showImportPreviewDialog({
    required String fileName,
    required List<PlayerCsvImportRow> rows,
  }) {
    final previewRows = rows.take(math.min(rows.length, 8)).toList();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar importacao'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arquivo: $fileName'),
                const SizedBox(height: 8),
                Text('Jogadores encontrados: ${rows.length}'),
                const SizedBox(height: 12),
                const Text(
                  'Primeiros nomes encontrados:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: math.min(previewRows.length, 4) * 72.0,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: previewRows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = previewRows[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.fullName),
                        subtitle: Text(
                          'Posicao: ${item.primaryPosition ?? 'nao_informado'} | CPF: ${item.cpf ?? '-'}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImportResultDialog(PlayerCsvImportResult result) {
    final errorPreview = result.errors.take(8).join('\n');

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importacao concluida'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Criados: ${result.createdCount}'),
                  Text('Atualizados: ${result.updatedCount}'),
                  Text('Vinculados ao elenco: ${result.rosterLinkedCount}'),
                  Text('Reativados no elenco: ${result.rosterReactivatedCount}'),
                  Text('Ignorados com erro: ${result.skippedCount}'),
                  if (result.errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Erros encontrados:',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(errorPreview),
                    if (result.errors.length > 8)
                      Text('...e mais ${result.errors.length - 8} erro(s).'),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
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
        actions: [
          IconButton(
            onPressed: _isImportingCsv ? null : _pickAndImportCsv,
            tooltip: 'Importar jogadores via CSV',
            icon: _isImportingCsv
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
          ),
        ],
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
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.file_upload_outlined),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Voce pode importar jogadores por CSV e eles ja entram vinculados a este time.',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('Modelo: modelo_importacao_jogadores.csv'),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.tonalIcon(
                                    onPressed: _isImportingCsv ? null : _pickAndImportCsv,
                                    icon: const Icon(Icons.upload_file_outlined),
                                    label: const Text('Importar CSV'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
