import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/admin_competition_overview_model.dart';
import '../../models/competition_model.dart';
import '../../models/viewer_match_model.dart';
import '../../repositories/viewer_repository.dart';
import 'viewer_match_detail_page.dart';

class ViewerCompetitionMatchesPage extends StatefulWidget {
  final CompetitionModel competition;

  const ViewerCompetitionMatchesPage({
    super.key,
    required this.competition,
  });

  @override
  State<ViewerCompetitionMatchesPage> createState() =>
      _ViewerCompetitionMatchesPageState();
}

class _ViewerCompetitionMatchesPageState
    extends State<ViewerCompetitionMatchesPage> {
  final _repository = ViewerRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<ViewerMatchModel> _matches = [];
  CompetitionOverviewDetails? _details;
  String _selectedTab = 'classification';

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final results = await Future.wait([
        _repository.getCompetitionMatches(widget.competition.id),
        _repository.getCompetitionDetails(widget.competition),
      ]);
      final matches = results[0] as List<ViewerMatchModel>;
      final details = results[1] as CompetitionOverviewDetails;

      if (!mounted) return;

      setState(() {
        _matches = matches;
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar partidas: $e';
        _isLoading = false;
      });
    }
  }

  List<ViewerMatchModel> get _orderedMatches => _matches;

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    final normalized = value.replaceAll('_', ' ');
    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _timeLabel(ViewerMatchModel match) {
    if (match.status == 'em_andamento') {
      final minute = (match.currentMinute ?? 0).toString().padLeft(2, '0');
      final second = (match.currentSecond ?? 0).toString().padLeft(2, '0');
      return '$minute:$second';
    }

    if (match.matchDatetime == null || match.matchDatetime!.isEmpty) {
      return '--:--';
    }

    final parsed = DateTime.tryParse(match.matchDatetime!);
    if (parsed == null) return '--:--';

    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _phaseLabel(ViewerMatchModel match) {
    if (match.status == 'em_andamento') return 'Ao vivo';
    if (match.status == 'finalizado') return 'FT';
    return _stageLabel(match.matchStage);
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'classificatoria':
        return 'Class.';
      case 'final':
        return 'Final';
      case 'terceiro_lugar':
        return '3° Lugar';
      case 'semifinal':
        return 'Semi';
      case 'quartas':
        return 'Quartas';
      default:
        return 'Jogo';
    }
  }

  Color _phaseColor(ViewerMatchModel match) {
    if (match.status == 'em_andamento') return const Color(0xFFFF5B5B);
    if (match.status == 'finalizado') return const Color(0xFFB0BEC5);
    return const Color(0xFF4FC3F7);
  }

  Widget _buildShield(String? url) {
    return SizedBox(
      width: 28,
      height: 28,
      child: url == null || url.isEmpty
          ? const Icon(
              Icons.shield_outlined,
              size: 20,
              color: Colors.white70,
            )
          : Image.network(
              url,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.shield_outlined,
                size: 20,
                color: Colors.white70,
              ),
            ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final selected = _selectedTab == tab;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            _selectedTab = tab;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF4FC3F7).withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4FC3F7).withValues(alpha: 0.60)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF4FC3F7) : Colors.white70,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompetitionCover() {
    final imageUrl = widget.competition.imageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          imageUrl,
          width: 126,
          height: 126,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultCompetitionCover(),
        ),
      );
    }

    return _buildDefaultCompetitionCover();
  }

  Widget _buildDefaultCompetitionCover() {
    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B7F7A),
            Color(0xFF164E8C),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(
        Icons.emoji_events_outlined,
        color: Colors.white,
        size: 54,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171C23),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildTableShield(String? url, {double size = 24}) {
    return SizedBox(
      width: size,
      height: size,
      child: url == null || url.isEmpty
          ? Icon(
              Icons.shield_outlined,
              size: size * 0.78,
              color: Colors.white70,
            )
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.shield_outlined,
                size: size * 0.78,
                color: Colors.white70,
              ),
            ),
    );
  }

  Widget _buildValueCell(
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
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String label, {
    required double width,
    TextAlign align = TextAlign.center,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStandingsSection() {
    final details = _details;
    if (details == null || details.standings.isEmpty) {
      return _buildSection(
        title: 'Classificação',
        child: const Text(
          'Ainda nao ha dados suficientes para montar a classificação.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final qualifiedCount = widget.competition.advancingTeamCount ?? 0;

    return _buildSection(
      title: 'Classificação',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(constraints.maxWidth, 960.0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          color: Colors.white.withValues(alpha: 0.04),
                          child: Row(
                            children: [
                              _buildHeaderCell('#', width: 48),
                              const Expanded(
                                child: Text(
                                  'Time',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _buildHeaderCell('J', width: 54),
                              _buildHeaderCell('V', width: 54),
                              _buildHeaderCell('E', width: 54),
                              _buildHeaderCell('D', width: 54),
                              _buildHeaderCell('GP', width: 64),
                              _buildHeaderCell('GC', width: 64),
                              _buildHeaderCell('SG', width: 64),
                              _buildHeaderCell('AVG', width: 70),
                              _buildHeaderCell('PTS', width: 70),
                            ],
                          ),
                        ),
                        for (final row in details.standings)
                          _buildStandingsRow(
                            row,
                            qualified: qualifiedCount > 0 &&
                                row.position <= qualifiedCount,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '*Classificam os dois primeiros colocados para a final e o terceiro e quarto colocados para a disputa de 3° Lugar.',
                style: TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStandingsRow(
    CompetitionStandingsRow row, {
    required bool qualified,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: qualified
            ? const Color(0xFF22C55E).withValues(alpha: 0.18)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Align(
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: qualified
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${row.position}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildTableShield(row.team.shieldUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.team.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildValueCell(row.played, width: 54),
          _buildValueCell(row.wins, width: 54),
          _buildValueCell(row.draws, width: 54),
          _buildValueCell(row.losses, width: 54),
          _buildValueCell(row.goalsFor, width: 64),
          _buildValueCell(row.goalsAgainst, width: 64),
          _buildValueCell(row.goalDifference, width: 64),
          _buildValueCell(row.goalAverage.toStringAsFixed(2), width: 70),
          _buildValueCell(row.points, width: 70, isBold: true),
        ],
      ),
    );
  }

  Widget _buildRankingsSection() {
    final details = _details;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 850;
        final width = twoColumns
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        final scorers = SizedBox(
          width: width,
          child: _buildSection(
            title: 'Artilheiros',
            child: _buildScorersList(details?.topScorers ?? const []),
          ),
        );

        final goalkeepers = SizedBox(
          width: width,
          child: _buildSection(
            title: 'Goleiros',
            child: _buildGoalkeepersList(details?.topGoalkeepers ?? const []),
          ),
        );

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [scorers, goalkeepers],
        );
      },
    );
  }

  Widget _buildScorersList(List<CompetitionTopScorerRow> rows) {
    if (rows.isEmpty) {
      return const Text(
        'Ainda nao ha gols lancados para esta competicao.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          _buildRankingRow(
            position: i + 1,
            shieldUrl: rows[i].team.shieldUrl,
            teamName: rows[i].team.displayName,
            name: rows[i].playerName,
            value: '${rows[i].goals} gol${rows[i].goals == 1 ? '' : 's'}',
          ),
      ],
    );
  }

  Widget _buildGoalkeepersList(List<CompetitionGoalkeeperRow> rows) {
    if (rows.isEmpty) {
      return const Text(
        'Ainda nao ha defesas registradas para esta competicao.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          _buildRankingRow(
            position: i + 1,
            shieldUrl: rows[i].team.shieldUrl,
            teamName: rows[i].team.displayName,
            name: rows[i].goalkeeperName,
            value: '${rows[i].savePercentage.toStringAsFixed(1)}%',
          ),
      ],
    );
  }

  Widget _buildRankingRow({
    required int position,
    required String? shieldUrl,
    required String teamName,
    required String name,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '$position',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _buildTableShield(shieldUrl, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teamName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF4FC3F7),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchRow(ViewerMatchModel match) {
    final phaseColor = _phaseColor(match);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ViewerMatchDetailPage(match: match),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 74,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeLabel(match),
                    style: TextStyle(
                      color: match.status == 'em_andamento'
                          ? phaseColor
                          : Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _phaseLabel(match),
                    style: TextStyle(
                      color: phaseColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 68,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  _ViewerScoreLine(
                    shield: _buildShield(match.homeTeamShieldUrl),
                    teamName: match.homeTeamName,
                    score: match.scoreHome,
                  ),
                  const SizedBox(height: 10),
                  _ViewerScoreLine(
                    shield: _buildShield(match.awayTeamShieldUrl),
                    teamName: match.awayTeamName,
                    score: match.scoreAway,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1016),
      appBar: AppBar(
        title: Text(widget.competition.shortName ?? widget.competition.name),
        backgroundColor: const Color(0xFF0B1016),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF11161D),
                                  Color(0xFF1A212B),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildCompetitionCover(),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                Text(
                                  widget.competition.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_titleCase(widget.competition.category)} ${_titleCase(widget.competition.gender)} • ${widget.competition.year}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _buildTabButton(
                                'classification',
                                'Classificação',
                              ),
                              const SizedBox(width: 12),
                              _buildTabButton('matches', 'Partidas'),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_selectedTab == 'classification') ...[
                            _buildStandingsSection(),
                            const SizedBox(height: 18),
                            _buildRankingsSection(),
                          ] else
                            _buildSection(
                              title: 'Partidas',
                              child: _orderedMatches.isEmpty
                                  ? const Text(
                                      'Nenhuma partida encontrada.',
                                      style: TextStyle(color: Colors.white70),
                                    )
                                  : Column(
                                      children: [
                                        for (var i = 0;
                                            i < _orderedMatches.length;
                                            i++) ...[
                                          _buildMatchRow(_orderedMatches[i]),
                                          if (i != _orderedMatches.length - 1)
                                            Divider(
                                              height: 1,
                                              color: Colors.white.withValues(
                                                alpha: 0.06,
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _ViewerScoreLine extends StatelessWidget {
  final Widget shield;
  final String teamName;
  final int score;

  const _ViewerScoreLine({
    required this.shield,
    required this.teamName,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        shield,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            teamName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        Text(
          '$score',
          style: const TextStyle(
            color: Color(0xFFFF5B5B),
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}
