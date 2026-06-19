import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/admin_competition_overview_model.dart';
import '../../models/competition_model.dart';
import '../../repositories/admin_competition_overview_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import 'competition_list_page.dart';

class AdminCompetitionsPage extends StatefulWidget {
  const AdminCompetitionsPage({super.key});

  @override
  State<AdminCompetitionsPage> createState() => _AdminCompetitionsPageState();
}

class _AdminCompetitionsPageState extends State<AdminCompetitionsPage> {
  final _repository = AdminCompetitionOverviewRepository();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  String _search = '';
  List<CompetitionModel> _competitions = [];

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.getCompetitionsOrderedByDate();

      if (!mounted) return;

      setState(() {
        _competitions = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar competições: $e';
        _isLoading = false;
      });
    }
  }

  List<CompetitionModel> get _filteredCompetitions {
    final normalized = _search.trim().toLowerCase();
    if (normalized.isEmpty) return _competitions;

    return _competitions.where((item) {
      return item.name.toLowerCase().contains(normalized) ||
          (item.shortName ?? '').toLowerCase().contains(normalized) ||
          item.year.toString().contains(normalized);
    }).toList();
  }

  String _competitionDateLabel(CompetitionModel item) {
    final start = _formatDate(item.startDate);
    final end = _formatDate(item.endDate);

    if (start != null && end != null) {
      return '$start a $end';
    }
    if (start != null) return start;
    if (end != null) return end;
    return '${item.year}';
  }

  String? _formatDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
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
        title: const Text('Competições'),
      ),
      body: AppBackdrop(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : RefreshIndicator(
                    onRefresh: _loadCompetitions,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppThemeColors.primaryDeep,
                                AppThemeColors.info,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Visão completa das competições',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Consulte times, jogos, classificação, artilharia e goleiros em uma leitura pronta para operação.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() {
                                    _search = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Pesquisar competição',
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  Chip(
                                    avatar: const Icon(Icons.emoji_events_outlined),
                                    label: Text(
                                      '${_filteredCompetitions.length} competição${_filteredCompetitions.length == 1 ? '' : 'ões'}',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const CompetitionListPage(),
                                        ),
                                      );
                                      await _loadCompetitions();
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Cadastro e edição'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_filteredCompetitions.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Nenhuma competição encontrada para a busca informada.',
                              ),
                            ),
                          )
                        else
                          ..._filteredCompetitions.map(
                            (competition) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _CompetitionOverviewTile(
                                competition: competition,
                                competitionDateLabel:
                                    _competitionDateLabel(competition),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _CompetitionOverviewTile extends StatefulWidget {
  final CompetitionModel competition;
  final String competitionDateLabel;

  const _CompetitionOverviewTile({
    required this.competition,
    required this.competitionDateLabel,
  });

  @override
  State<_CompetitionOverviewTile> createState() =>
      _CompetitionOverviewTileState();
}

class _CompetitionOverviewTileState extends State<_CompetitionOverviewTile> {
  final _repository = AdminCompetitionOverviewRepository();

  bool _isExpanded = false;
  bool _isLoading = false;
  String? _errorMessage;
  CompetitionOverviewDetails? _details;

  Future<void> _toggleExpanded() async {
    final nextExpanded = !_isExpanded;
    setState(() {
      _isExpanded = nextExpanded;
    });

    if (nextExpanded && _details == null && !_isLoading) {
      await _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _repository.getCompetitionDetails(widget.competition);

      if (!mounted) return;

      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar detalhes da competição: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.competition;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppThemeColors.secondarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: AppThemeColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.competitionDateLabel} • ${item.category} • ${item.gender} • ${item.competitionType}',
                          style: const TextStyle(
                            color: AppThemeColors.slate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if ((item.advancingTeamCount ?? 0) > 0) ...[
                          const SizedBox(height: 10),
                          Chip(
                            label: Text(
                              'Classificam ${item.advancingTeamCount} time${item.advancingTeamCount == 1 ? '' : 's'}',
                            ),
                            backgroundColor: AppThemeColors.primarySoft,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppThemeColors.slate,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_errorMessage!),
                        )
                      : _details == null
                          ? const SizedBox.shrink()
                          : _CompetitionOverviewContent(
                              competition: widget.competition,
                              details: _details!,
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionOverviewContent extends StatelessWidget {
  final CompetitionModel competition;
  final CompetitionOverviewDetails details;

  const _CompetitionOverviewContent({
    required this.competition,
    required this.details,
  });

  static const _darkBackground = Color(0xFF0C1118);
  static const _darkPanel = Color(0xFF141B24);
  static const _lineColor = Color(0x1FFFFFFF);
  static const _qualifiedColor = Color(0xFF1D8F52);

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '--/--/----';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '--/--/----';
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '--:--';
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'finalizado':
        return 'Finalizado';
      case 'em_andamento':
        return 'Ao vivo';
      default:
        return 'Agendado';
    }
  }

  String _venueLabel(CompetitionMatchOverview match) {
    final parts = [
      if (match.venueName != null && match.venueName!.isNotEmpty) match.venueName!,
      if (match.venueCity != null && match.venueCity!.isNotEmpty) match.venueCity!,
      if (match.venueState != null && match.venueState!.isNotEmpty) match.venueState!,
    ];

    if (parts.isEmpty) return 'Local não informado';
    return parts.join(' • ');
  }

  Widget _buildShield(String? url, {double size = 28}) {
    if (url == null || url.isEmpty) {
      return Icon(
        Icons.shield_outlined,
        size: size,
        color: Colors.white70,
      );
    }

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Icon(
          Icons.shield_outlined,
          size: size,
          color: Colors.white70,
        );
      },
    );
  }

  Widget _buildDarkSection({
    required String title,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _darkPanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _darkBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            competition.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${competition.category} • ${competition.gender} • ${competition.year}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeaderChip('Times', '${details.teams.length}'),
              _buildHeaderChip('Jogos', '${details.matches.length}'),
              _buildHeaderChip(
                'Finalizados',
                '${details.matches.where((item) => item.status == 'finalizado').length}',
              ),
              if ((competition.advancingTeamCount ?? 0) > 0)
                _buildHeaderChip(
                  'Classificam',
                  '${competition.advancingTeamCount}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'inherit'),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsSection() {
    if (details.teams.isEmpty) {
      return _buildDarkSection(
        title: 'Times',
        subtitle: 'Os times aparecem conforme os jogos cadastrados na competição.',
        child: const Text(
          'Ainda não há times vinculados por jogos nesta competição.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return _buildDarkSection(
      title: 'Times',
      subtitle: 'Escudo, nome e estado dos times que já aparecem nos jogos cadastrados.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          var columns = 1;
          if (width >= 920) {
            columns = 3;
          } else if (width >= 640) {
            columns = 2;
          }

          final cardWidth = columns == 1
              ? width
              : (width - ((columns - 1) * 12)) / columns;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: details.teams.map((team) {
              return Container(
                width: cardWidth,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _lineColor),
                ),
                child: Row(
                  children: [
                    _buildShield(team.shieldUrl, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            team.state ?? '-',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMatchesSection() {
    if (details.matches.isEmpty) {
      return _buildDarkSection(
        title: 'Jogos',
        child: const Text(
          'Nenhum jogo cadastrado nesta competição.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return _buildDarkSection(
      title: 'Jogos',
      child: Column(
        children: [
          for (var i = 0; i < details.matches.length; i++) ...[
            _buildMatchCard(details.matches[i]),
            if (i != details.matches.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchCard(CompetitionMatchOverview match) {
    final statusLabel = _statusLabel(match.status);
    final statusColor = match.status == 'finalizado'
        ? const Color(0xFFB0BEC5)
        : match.status == 'em_andamento'
            ? const Color(0xFFFF5B5B)
            : const Color(0xFF4FC3F7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lineColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMatchTeam(
                  team: match.homeTeam,
                  alignEnd: false,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${match.scoreHome} x ${match.scoreAway}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: _buildMatchTeam(
                  team: match.awayTeam,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_formatDate(match.matchDatetime)} • ${_formatTime(match.matchDatetime)} • ${_venueLabel(match)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTeam({
    required CompetitionTeamOverview team,
    required bool alignEnd,
  }) {
    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) ...[
          _buildShield(team.shieldUrl, size: 28),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            team.name,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (alignEnd) ...[
          const SizedBox(width: 10),
          _buildShield(team.shieldUrl, size: 28),
        ],
      ],
    );
  }

  Widget _buildStandingsSection() {
    if (details.standings.isEmpty) {
      return _buildDarkSection(
        title: 'Tabela da competição',
        child: const Text(
          'A tabela será calculada quando houver jogos finalizados.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final qualifiedCount = competition.advancingTeamCount ?? 0;

    return _buildDarkSection(
      title: 'Tabela da competição',
      subtitle:
          'Vitória vale 2 pontos, empate vale 1 e derrota vale 0. Jogos contam apenas quando estão finalizados.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(constraints.maxWidth, 980.0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: _darkBackground,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        children: [
                          _buildStandingsHeader(tableWidth: tableWidth),
                          for (final row in details.standings)
                            _buildStandingsRow(
                              row,
                              tableWidth: tableWidth,
                              highlight: qualifiedCount > 0 &&
                                  row.position <= qualifiedCount,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (qualifiedCount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '*Classificam ${qualifiedCount} time${qualifiedCount == 1 ? '' : 's'} para a próxima fase.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStandingsHeader({
    required double tableWidth,
  }) {
    return SizedBox(
      width: tableWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 54, child: _headerLabel('#')),
            Expanded(child: _headerLabel('Time', align: TextAlign.start)),
            SizedBox(width: 64, child: _headerLabel('J')),
            SizedBox(width: 64, child: _headerLabel('V')),
            SizedBox(width: 64, child: _headerLabel('E')),
            SizedBox(width: 64, child: _headerLabel('D')),
            SizedBox(width: 80, child: _headerLabel('GP')),
            SizedBox(width: 80, child: _headerLabel('GC')),
            SizedBox(width: 80, child: _headerLabel('SG')),
            SizedBox(width: 80, child: _headerLabel('PTS')),
          ],
        ),
      ),
    );
  }

  Widget _buildStandingsRow(
    CompetitionStandingsRow row, {
    required double tableWidth,
    required bool highlight,
  }) {
    return SizedBox(
      width: tableWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: highlight
              ? _qualifiedColor.withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: highlight ? _qualifiedColor : Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${row.position}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildShield(row.team.shieldUrl, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.team.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _fixedValueCell(row.played, width: 64),
            _fixedValueCell(row.wins, width: 64),
            _fixedValueCell(row.draws, width: 64),
            _fixedValueCell(row.losses, width: 64),
            _fixedValueCell(row.goalsFor, width: 80),
            _fixedValueCell(row.goalsAgainst, width: 80),
            _fixedValueCell(row.goalDifference, width: 80),
            _fixedValueCell(row.points, width: 80, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTopScorersSection() {
    return _buildDarkSection(
      title: 'Artilheiros',
      subtitle: 'Top 10 jogadores com mais gols na competição.',
      child: _buildLeaderboardTable(
        minWidth: 860,
        headerBuilder: (tableWidth) => _buildScorerHeader(tableWidth),
        rowsBuilder: (tableWidth) => details.topScorers.isEmpty
            ? [
                _buildEmptyTableRow(
                  'Nenhum dado de artilharia encontrado para esta competição.',
                  tableWidth: tableWidth,
                ),
              ]
            : [
                for (var i = 0; i < details.topScorers.length; i++)
                  _buildLeaderboardRow(
                    tableWidth: tableWidth,
                    index: i + 1,
                    team: details.topScorers[i].team,
                    athleteName: details.topScorers[i].playerName,
                    lastValue: '${details.topScorers[i].goals}',
                  ),
              ],
      ),
    );
  }

  Widget _buildTopGoalkeepersSection() {
    return _buildDarkSection(
      title: 'Goleiros',
      subtitle: 'Top 10 goleiros pela maior porcentagem de defesa.',
      child: _buildLeaderboardTable(
        minWidth: 860,
        headerBuilder: (tableWidth) => _buildGoalkeeperHeader(tableWidth),
        rowsBuilder: (tableWidth) => details.topGoalkeepers.isEmpty
            ? [
                _buildEmptyTableRow(
                  'Nenhum dado de goleiro encontrado para esta competição.',
                  tableWidth: tableWidth,
                ),
              ]
            : [
                for (var i = 0; i < details.topGoalkeepers.length; i++)
                  _buildGoalkeeperLeaderboardRow(
                    tableWidth: tableWidth,
                    index: i + 1,
                    item: details.topGoalkeepers[i],
                  ),
              ],
      ),
    );
  }

  Widget _buildLeaderboardTable({
    required double minWidth,
    required Widget Function(double tableWidth) headerBuilder,
    required List<Widget> Function(double tableWidth) rowsBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(constraints.maxWidth, minWidth).toDouble();

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            color: _darkBackground,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    headerBuilder(tableWidth),
                    ...rowsBuilder(tableWidth),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardRow({
    required double tableWidth,
    required int index,
    required CompetitionTeamOverview team,
    required String athleteName,
    required String lastValue,
  }) {
    return SizedBox(
      width: tableWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            _fixedValueCell(index, width: 54),
            SizedBox(
              width: 220,
              child: Row(
                children: [
                  _buildShield(team.shieldUrl, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      team.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                athleteName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            _fixedValueCell(lastValue, width: 90, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalkeeperLeaderboardRow({
    required double tableWidth,
    required int index,
    required CompetitionGoalkeeperRow item,
  }) {
    return SizedBox(
      width: tableWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            _fixedValueCell(index, width: 54),
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  _buildShield(item.team.shieldUrl, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.team.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.goalkeeperName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            _fixedValueCell(item.saves, width: 88),
            _fixedValueCell(item.shotsFaced, width: 88),
            _fixedValueCell(
              '${item.savePercentage.toStringAsFixed(1)}%',
              width: 110,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorerHeader(double tableWidth) {
    return SizedBox(
      width: tableWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 54, child: _headerLabel('#')),
            SizedBox(width: 220, child: _headerLabel('Time', align: TextAlign.start)),
            const SizedBox(width: 14),
            Expanded(child: _headerLabel('Jogador', align: TextAlign.start)),
            const SizedBox(width: 14),
            SizedBox(width: 90, child: _headerLabel('Gols')),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalkeeperHeader(double tableWidth) {
    return SizedBox(
      width: tableWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 54, child: _headerLabel('#')),
            SizedBox(width: 200, child: _headerLabel('Time', align: TextAlign.start)),
            const SizedBox(width: 14),
            Expanded(child: _headerLabel('Goleiro', align: TextAlign.start)),
            const SizedBox(width: 14),
            SizedBox(width: 88, child: _headerLabel('Defesas')),
            SizedBox(width: 88, child: _headerLabel('Chutes')),
            SizedBox(width: 110, child: _headerLabel('% Defesa')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTableRow(
    String message, {
    required double tableWidth,
  }) {
    return SizedBox(
      width: tableWidth,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _fixedValueCell(
    Object value, {
    required double width,
    bool isBold = false,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _headerLabel(
    String label, {
    TextAlign align = TextAlign.center,
  }) {
    return Text(
      label,
      textAlign: align,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _darkBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTeamsSection(),
          const SizedBox(height: 16),
          _buildMatchesSection(),
          const SizedBox(height: 16),
          _buildStandingsSection(),
          const SizedBox(height: 16),
          _buildTopScorersSection(),
          const SizedBox(height: 16),
          _buildTopGoalkeepersSection(),
        ],
      ),
    );
  }
}
