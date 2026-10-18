import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../repositories/wa_team_report_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';

class WaTeamReportsPage extends StatefulWidget {
  const WaTeamReportsPage({super.key});

  @override
  State<WaTeamReportsPage> createState() => _WaTeamReportsPageState();
}

class _WaTeamReportsPageState extends State<WaTeamReportsPage> {
  final _repository = WaTeamReportRepository();
  bool _isLoading = true;
  bool _isLoadingCompetition = false;
  String? _errorMessage;
  String _genderFilter = 'feminino';
  List<Map<String, dynamic>> _competitions = [];
  Map<String, dynamic>? _selectedCompetition;
  Map<String, dynamic>? _reportData;

  List<Map<String, dynamic>> get _visibleCompetitions => _competitions
      .where((item) => _competitionGender(item) == _genderFilter)
      .toList();

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    try {
      final competitions = await _repository.getCompetitions();
      if (!mounted) return;
      setState(() {
        _competitions = competitions;
        _isLoading = false;
      });

      final visibleCompetitions = _visibleCompetitions;
      final initial = visibleCompetitions.isNotEmpty
          ? visibleCompetitions.first
          : competitions.isNotEmpty
          ? competitions.first
          : null;
      if (initial != null) {
        _genderFilter = _competitionGender(initial);
        await _selectCompetition(initial);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível carregar as competições: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCompetition(Map<String, dynamic> competition) async {
    setState(() {
      _selectedCompetition = competition;
      _isLoadingCompetition = true;
      _reportData = null;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getCompetitionReport(
        competition: competition,
      );
      if (!mounted) return;
      setState(() {
        _reportData = data;
        _isLoadingCompetition = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível carregar os dados da competição: $e';
        _isLoadingCompetition = false;
      });
    }
  }

  Future<void> _createPdf(Map<String, dynamic> team) async {
    final data = _reportData;
    final competition = _selectedCompetition;
    if (data == null || competition == null) return;

    final teamId = team['id'] as String;
    final name = _displayTeamName(team);
    final pdf = _buildPdf(reportData: data, teamId: teamId, teamName: name);
    final bytes = await pdf.save();
    final safeName = name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final filename = 'copa_wa_${_genderFilter}_$safeName.pdf';

    await Printing.layoutPdf(name: filename, onLayout: (_) async => bytes);
  }

  pw.Document _buildPdf({
    required Map<String, dynamic> reportData,
    required String teamId,
    required String teamName,
  }) {
    final competition = reportData['competition'] as Map<String, dynamic>;
    final matches = (reportData['matches'] as List<Map<String, dynamic>>)
        .where(
          (match) =>
              match['home_team_id'] == teamId ||
              match['away_team_id'] == teamId,
        )
        .toList();
    final teamStats = _statsFor(reportData, 'team_stats', teamId);
    final players = _athletesFor(reportData, 'players', teamId);
    final goalkeepers = _athletesFor(reportData, 'goalkeepers', teamId);
    final shots = _shotsFor(reportData, teamId);
    final shotSections = <pw.Widget>[];
    for (final player in players) {
      final playerId = player['player_id'] as String?;
      if (playerId == null) continue;
      final playerRows = _playerShotRows(playerId, shots);
      if (playerRows.isEmpty) continue;
      shotSections.add(pw.SizedBox(height: 10));
      shotSections.add(
        pw.Text(
          player['player_name'] as String? ?? 'Atleta',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      );
      shotSections.add(pw.SizedBox(height: 4));
      shotSections.add(
        table([
          'Zona de arremesso',
          'Zona do gol',
          'Chutes',
          'Gols',
          'Defesas',
          'Fora',
          'Trave',
          'Bloqueados',
        ], playerRows),
      );
    }
    final pdf = pw.Document();
    const headerStyle = pw.TextStyle(
      fontSize: 9,
      color: PdfColors.white,
      fontWeight: pw.FontWeight.bold,
    );
    const cellStyle = pw.TextStyle(fontSize: 8.5);
    final headingStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromInt(0xFF0F766E),
    );

    pw.Widget table(List<String> headers, List<List<String>> rows) {
      if (rows.isEmpty) {
        return pw.Text('Sem dados registrados.');
      }
      return pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: headerStyle,
        cellStyle: cellStyle,
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F766E)),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        headerAlignment: pw.Alignment.centerLeft,
        cellAlignments: {
          for (var i = 1; i < headers.length; i++) i: pw.Alignment.center,
        },
      );
    }

    String val(String key) => _number(teamStats[key]);
    String pct(String goalsKey, String shotsKey) {
      final goals = _num(teamStats[goalsKey]);
      final attempts = _num(teamStats[shotsKey]);
      if (attempts == 0) return '0,0%';
      return '${(goals / attempts * 100).toStringAsFixed(1).replaceAll('.', ',')}%';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            'HANDBRASIL STATS  •  ${competition['year'] ?? ''}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            competition['name'] as String? ?? 'Copa W.A',
            style: pw.TextStyle(
              fontSize: 19,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF10233F),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            teamName,
            style: pw.TextStyle(
              fontSize: 15,
              color: PdfColor.fromInt(0xFF0F766E),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Relatório da equipe • ${matches.length} partidas cadastradas',
          ),
          pw.SizedBox(height: 18),
          pw.Text('Resumo do time', style: headingStyle),
          pw.SizedBox(height: 7),
          table(
            ['Indicador', 'Total'],
            [
              ['Chutes', val('shots')],
              ['Gols', val('goals_scored')],
              ['Aproveitamento', pct('goals_scored', 'shots')],
              ['Gols de 9m', val('goals_9m')],
              ['Chutes de 9m', val('shots_9m')],
              ['Gols de 7m', val('goals_7m')],
              ['Chutes de 7m', val('shots_7m')],
              ['Gols de 6m', val('goals_6m')],
              ['Chutes de 6m', val('shots_6m')],
              ['Contra-ataque', val('counter_attack_goals')],
              ['Arremessos para fora', val('shots_out')],
              ['Arremessos defendidos', val('shots_saved')],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text('Partidas', style: headingStyle),
          pw.SizedBox(height: 7),
          table(
            ['Data', 'Fase', 'Mandante', 'Placar', 'Visitante', 'Status'],
            matches.map((match) {
              final home = _teamFromMatch(match, 'home_team');
              final away = _teamFromMatch(match, 'away_team');
              return [
                _date(match['match_datetime']),
                _stage(match['match_stage'] as String?),
                _displayTeamName(home),
                '${match['score_home'] ?? 0} x ${match['score_away'] ?? 0}',
                _displayTeamName(away),
                _status(match['status'] as String?),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Atletas', style: headingStyle),
          pw.SizedBox(height: 7),
          table(
            ['Atleta', 'Jogos', 'Gols', 'Chutes', 'Aprov. %', '9m', '7m'],
            players
                .map(
                  (row) => [
                    row['player_name'] as String? ?? 'Atleta',
                    _number(row['matches_played']),
                    _number(row['goals']),
                    _number(row['shots']),
                    _percent(row['shot_percentage']),
                    _number(row['goals_9m']),
                    _number(row['goals_7m']),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Goleiros', style: headingStyle),
          pw.SizedBox(height: 7),
          table(
            [
              'Goleiro',
              'Jogos',
              'Defesas',
              'Chutes sofridos',
              'Gols sofridos',
              '% defesa',
            ],
            goalkeepers
                .map(
                  (row) => [
                    row['goalkeeper_name'] as String? ?? 'Goleiro',
                    _number(row['matches_played']),
                    _number(row['saves']),
                    _number(row['shots_faced']),
                    _number(row['goals_conceded']),
                    _percent(row['save_percentage']),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Zonas e destinos por atleta', style: headingStyle),
          pw.SizedBox(height: 7),
          if (shotSections.isEmpty)
            pw.Text('Nenhum arremesso individual foi registrado.')
          else
            ...shotSections,
        ],
      ),
    );
    return pdf;
  }

  List<List<String>> _playerShotRows(
    String playerId,
    List<Map<String, dynamic>> shots,
  ) {
    final byRoute = <String, Map<String, int>>{};
    final labelsByRoute = <String, (String, String)>{};
    for (final shot in shots) {
      if (shot['player_id'] != playerId) continue;
      final zoneId = (shot['zone_id'] as num?)?.toInt();
      final shotType = (shot['shot_type'] as String? ?? '').toLowerCase();
      final shotZone = shotType.contains('7')
          ? '7M'
          : zoneId == null
          ? 'Sem zona'
          : 'Z${zoneId.toString().padLeft(2, '0')}';
      final goalZoneId = (shot['goal_zone_id'] as num?)?.toInt();
      final goalZone = goalZoneId == null
          ? '-'
          : 'G${goalZoneId.toString().padLeft(2, '0')}';
      final route = '$shotZone->$goalZone';
      labelsByRoute[route] = (shotZone, goalZone);
      final counts = byRoute.putIfAbsent(
        route,
        () => {
          'shots': 0,
          'goal': 0,
          'saved': 0,
          'out': 0,
          'post': 0,
          'blocked': 0,
        },
      );
      counts['shots'] = counts['shots']! + 1;
      final result = (shot['shot_result'] as String? ?? '').toLowerCase();
      if (counts.containsKey(result)) counts[result] = counts[result]! + 1;
    }
    final routes = byRoute.keys.toList()..sort((a, b) => a.compareTo(b));
    return routes.map((route) {
      final labels = labelsByRoute[route]!;
      final counts = byRoute[route]!;
      return [
        labels.$1,
        labels.$2,
        '${counts['shots']}',
        '${counts['goal']}',
        '${counts['saved']}',
        '${counts['out']}',
        '${counts['post']}',
        '${counts['blocked']}',
      ];
    }).toList();
  }

  Map<String, dynamic> _statsFor(
    Map<String, dynamic> data,
    String collection,
    String teamId,
  ) {
    final values = data[collection] as Map<String, Map<String, dynamic>>;
    return values[teamId] ?? const {};
  }

  List<Map<String, dynamic>> _athletesFor(
    Map<String, dynamic> data,
    String collection,
    String teamId,
  ) {
    final values = data[collection] as Map<String, Map<String, dynamic>>;
    return values.values.where((row) => row['team_id'] == teamId).toList()
      ..sort((a, b) {
        final nameKey = collection == 'players'
            ? 'player_name'
            : 'goalkeeper_name';
        return ((a[nameKey] as String?) ?? '').compareTo(
          (b[nameKey] as String?) ?? '',
        );
      });
  }

  List<Map<String, dynamic>> _shotsFor(
    Map<String, dynamic> data,
    String teamId,
  ) {
    final values = data['shots'] as Map<String, List<Map<String, dynamic>>>;
    return values[teamId] ?? const [];
  }

  Map<String, dynamic> _teamFromMatch(Map<String, dynamic> match, String key) {
    final team = match[key];
    return team is Map ? Map<String, dynamic>.from(team) : const {};
  }

  String _displayTeamName(Map<String, dynamic> team) {
    final shortName = (team['short_name'] as String?)?.trim();
    if (shortName != null && shortName.isNotEmpty) return shortName;
    return team['name'] as String? ?? 'Equipe';
  }

  String _competitionGender(Map<String, dynamic> competition) {
    final gender = (competition['gender'] as String? ?? '').toLowerCase();
    final name = (competition['name'] as String? ?? '').toLowerCase();
    if (gender.contains('fem') || name.contains('femin')) return 'feminino';
    if (gender.contains('masc') || name.contains('mascul')) return 'masculino';
    return 'feminino';
  }

  num _num(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;

  String _number(dynamic value) => '${_num(value).toInt()}';

  String _percent(dynamic value) =>
      '${_num(value).toStringAsFixed(1).replaceAll('.', ',')}%';

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null ? '-' : DateFormat('dd/MM/yy').format(date);
  }

  String _stage(String? value) {
    switch (value) {
      case 'classificatoria':
        return 'Class.';
      case 'final':
        return 'Final';
      case 'terceiro_lugar':
        return '3º lugar';
      default:
        return value ?? '-';
    }
  }

  String _status(String? value) {
    switch (value) {
      case 'finalizado':
        return 'Finalizado';
      case 'ao_vivo':
        return 'Ao vivo';
      default:
        return 'Agendado';
    }
  }

  Widget _teamShield(Map<String, dynamic> team) {
    final url = team['shield_url'] as String?;
    if (url == null || url.isEmpty) {
      return const Icon(
        Icons.shield_outlined,
        size: 34,
        color: AppThemeColors.primary,
      );
    }
    return Image.network(
      url,
      width: 46,
      height: 46,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.shield_outlined,
        size: 34,
        color: AppThemeColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final competitions = _visibleCompetitions;
    final teams =
        (_reportData?['teams'] as Map<String, Map<String, dynamic>>?)?.values
            .toList() ??
        <Map<String, dynamic>>[];
    teams.sort((a, b) => _displayTeamName(a).compareTo(_displayTeamName(b)));

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios Copa W.A')),
      body: AppBackdrop(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'feminino',
                          label: Text('Feminino'),
                        ),
                        ButtonSegment(
                          value: 'masculino',
                          label: Text('Masculino'),
                        ),
                      ],
                      selected: {_genderFilter},
                      onSelectionChanged: (values) {
                        setState(() {
                          _genderFilter = values.first;
                          _selectedCompetition = null;
                          _reportData = null;
                        });
                        final visibleCompetitions = _visibleCompetitions;
                        final competition = visibleCompetitions.isEmpty
                            ? null
                            : visibleCompetitions.first;
                        if (competition != null)
                          _selectCompetition(competition);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (competitions.isNotEmpty)
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value:
                            competitions.any(
                              (item) =>
                                  item['id'] == _selectedCompetition?['id'],
                            )
                            ? competitions.firstWhere(
                                (item) =>
                                    item['id'] == _selectedCompetition?['id'],
                              )
                            : competitions.first,
                        decoration: const InputDecoration(
                          labelText: 'Competição',
                        ),
                        items: competitions
                            .map(
                              (competition) => DropdownMenuItem(
                                value: competition,
                                child: Text(
                                  '${competition['name']} • ${competition['year'] ?? ''}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (competition) {
                          if (competition != null)
                            _selectCompetition(competition);
                        },
                      ),
                    const SizedBox(height: 14),
                    if (_errorMessage != null)
                      Expanded(child: Center(child: Text(_errorMessage!)))
                    else if (competitions.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Não encontrei competições Copa W.A cadastradas.',
                          ),
                        ),
                      )
                    else if (_isLoadingCompetition)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (teams.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Esta competição ainda não tem partidas cadastradas.',
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: teams.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final team = teams[index];
                            return Card(
                              child: ListTile(
                                leading: _teamShield(team),
                                title: Text(
                                  _displayTeamName(team),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Relatório completo da equipe',
                                ),
                                trailing: FilledButton.icon(
                                  onPressed: () => _createPdf(team),
                                  icon: const Icon(Icons.download_outlined),
                                  label: const Text('Baixar PDF'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
