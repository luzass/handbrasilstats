import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/player_csv_import_result.dart';
import '../../models/player_csv_import_row.dart';
import '../../models/player_model.dart';
import '../../repositories/player_repository.dart';
import '../../utils/csv_utils.dart';
import '../../utils/player_csv_import_parser.dart';
import 'player_form_page.dart';

class PlayerListPage extends StatefulWidget {
  const PlayerListPage({super.key});

  @override
  State<PlayerListPage> createState() => _PlayerListPageState();
}

class _PlayerListPageState extends State<PlayerListPage> {
  final _repository = PlayerRepository();

  bool _isLoading = true;
  bool _isImportingCsv = false;
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

  Future<void> _pickAndImportCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
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
      final rows = parsePlayerCsvImportRows(csvContent);
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

      final importResult = await _repository.importPlayersFromRows(rows);

      if (!mounted) return;

      await _loadPlayers();

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
              : ListView(
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
                                    'Voce pode subir jogadores em massa por CSV e depois vincular ao elenco dos times.',
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
                    if (_players.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: Text('Nenhum jogador cadastrado.')),
                      )
                    else
                      ..._players.map((item) {
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
                      }),
                  ],
                ),
    );
  }
}
