import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/match_model.dart';
import '../../repositories/match_repository.dart';

class MatchFormPage extends StatefulWidget {
  final MatchModel? match;

  const MatchFormPage({
    super.key,
    this.match,
  });

  @override
  State<MatchFormPage> createState() => _MatchFormPageState();
}

class _MatchFormPageState extends State<MatchFormPage> {
  final _repository = MatchRepository();
  final _supabase = Supabase.instance.client;

  final _matchDatetimeController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueCityController = TextEditingController();
  final _venueStateController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _competitions = [];
  List<Map<String, dynamic>> _teams = [];

  String? _competitionId;
  String? _homeTeamId;
  String? _awayTeamId;
  String _status = 'agendado';
  String _scoutStatus = 'nao_iniciado';
  String? _currentPeriod;
  int? _currentMinute;
  int? _currentSecond;

  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;

  bool get isEditing => widget.match != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  String? _parseDateTimeToIso(String value) {
    if (value.trim().isEmpty) return null;

    try {
      final inputFormat = DateFormat('dd/MM/yyyy HH:mm');
      final dateTime = inputFormat.parseStrict(value.trim());
      return dateTime.toIso8601String();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final competitionsResponse = await _supabase
          .from('competitions')
          .select('id, name')
          .order('year', ascending: false);

      final teamsResponse = await _supabase
          .from('teams')
          .select('id, name')
          .order('name', ascending: true);

      final item = widget.match;

      if (!mounted) return;

      setState(() {
        _competitions = List<Map<String, dynamic>>.from(competitionsResponse);
        _teams = List<Map<String, dynamic>>.from(teamsResponse);

        if (item != null) {
          _competitionId = item.competitionId;
          _homeTeamId = item.homeTeamId;
          _awayTeamId = item.awayTeamId;

          if (item.matchDatetime != null && item.matchDatetime!.isNotEmpty) {
            try {
              final parsed = DateTime.parse(item.matchDatetime!);
              _matchDatetimeController.text =
                  DateFormat('dd/MM/yyyy HH:mm').format(parsed);
            } catch (_) {
              _matchDatetimeController.text = item.matchDatetime ?? '';
            }
          }

          _venueNameController.text = item.venueName ?? '';
          _venueCityController.text = item.venueCity ?? '';
          _venueStateController.text = item.venueState ?? '';
          _notesController.text = item.notes ?? '';
          _status = item.status;
          _scoutStatus = item.scoutStatus;
          _currentPeriod = item.currentPeriod;
          _currentMinute = item.currentMinute;
          _currentSecond = item.currentSecond;
        }

        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados iniciais: $e';
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_competitionId == null || _homeTeamId == null || _awayTeamId == null) {
      setState(() {
        _errorMessage = 'Selecione competição, time mandante e time visitante.';
      });
      return;
    }

    if (_homeTeamId == _awayTeamId) {
      setState(() {
        _errorMessage = 'Mandante e visitante não podem ser o mesmo time.';
      });
      return;
    }

    final parsedDateTime = _parseDateTimeToIso(_matchDatetimeController.text);

    if (_matchDatetimeController.text.trim().isNotEmpty && parsedDateTime == null) {
      setState(() {
        _errorMessage = 'Data/hora inválida. Use o formato dd/MM/yyyy HH:mm';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final model = MatchModel(
        id: widget.match?.id ?? '',
        competitionId: _competitionId!,
        homeTeamId: _homeTeamId!,
        awayTeamId: _awayTeamId!,
        matchDatetime: parsedDateTime,
        venueName: _venueNameController.text.trim().isEmpty
            ? null
            : _venueNameController.text.trim(),
        venueCity: _venueCityController.text.trim().isEmpty
            ? null
            : _venueCityController.text.trim(),
        venueState: _venueStateController.text.trim().isEmpty
            ? null
            : _venueStateController.text.trim(),
        status: _status,
        scoutStatus: _scoutStatus,
        currentPeriod: _currentPeriod,
        currentMinute: _currentMinute,
        currentSecond: _currentSecond,
        scoreHome: widget.match?.scoreHome ?? 0,
        scoreAway: widget.match?.scoreAway ?? 0,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (isEditing) {
        await _repository.updateMatch(model);
      } else {
        await _repository.createMatch(model);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar partida: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _matchDatetimeController.dispose();
    _venueNameController.dispose();
    _venueCityController.dispose();
    _venueStateController.dispose();
    _notesController.dispose();
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
        title: Text(isEditing ? 'Editar partida' : 'Nova partida'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _competitionId,
              decoration: const InputDecoration(
                labelText: 'Competição',
                border: OutlineInputBorder(),
              ),
              items: _competitions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['id'] as String,
                      child: Text(item['name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _competitionId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _homeTeamId,
              decoration: const InputDecoration(
                labelText: 'Time mandante',
                border: OutlineInputBorder(),
              ),
              items: _teams
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['id'] as String,
                      child: Text(item['name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _homeTeamId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _awayTeamId,
              decoration: const InputDecoration(
                labelText: 'Time visitante',
                border: OutlineInputBorder(),
              ),
              items: _teams
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['id'] as String,
                      child: Text(item['name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _awayTeamId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _matchDatetimeController,
              'Data/hora (ex: 10/05/2026 18:30)',
            ),
            _buildTextField(_venueNameController, 'Nome do ginásio'),
            _buildTextField(_venueCityController, 'Cidade'),
            _buildTextField(_venueStateController, 'Estado'),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status da partida',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'agendado', child: Text('Agendado')),
                DropdownMenuItem(value: 'em_andamento', child: Text('Em andamento')),
                DropdownMenuItem(value: 'finalizado', child: Text('Finalizado')),
                DropdownMenuItem(value: 'suspenso', child: Text('Suspenso')),
                DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
              ],
              onChanged: (value) {
                setState(() {
                  _status = value ?? 'agendado';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _scoutStatus,
              decoration: const InputDecoration(
                labelText: 'Status do scout',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'nao_iniciado', child: Text('Não iniciado')),
                DropdownMenuItem(value: 'em_coleta', child: Text('Em coleta')),
                DropdownMenuItem(value: 'revisao', child: Text('Revisão')),
                DropdownMenuItem(value: 'aprovado', child: Text('Aprovado')),
                DropdownMenuItem(value: 'publicado', child: Text('Publicado')),
              ],
              onChanged: (value) {
                setState(() {
                  _scoutStatus = value ?? 'nao_iniciado';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _currentPeriod,
              decoration: const InputDecoration(
                labelText: 'Período atual',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Não definido')),
                DropdownMenuItem(value: 'first_half', child: Text('1º tempo')),
                DropdownMenuItem(value: 'second_half', child: Text('2º tempo')),
                DropdownMenuItem(value: 'extra_time_1', child: Text('Prorrogação 1')),
                DropdownMenuItem(value: 'extra_time_2', child: Text('Prorrogação 2')),
                DropdownMenuItem(value: 'penalties', child: Text('Tiros')),
              ],
              onChanged: (value) {
                setState(() {
                  _currentPeriod = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(_notesController, 'Observações', maxLines: 4),
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
                    : Text(isEditing ? 'Salvar alterações' : 'Criar partida'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}