import 'package:flutter/material.dart';

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
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await _repository.getCompetitionMatches(
        widget.competition.id,
      );

      if (!mounted) return;

      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar partidas: $e';
        _isLoading = false;
      });
    }
  }

  int get _liveCount =>
      _matches.where((match) => match.status == 'em_andamento').length;

  int get _finishedCount =>
      _matches.where((match) => match.status == 'finalizado').length;

  int get _upcomingCount => _matches
      .where(
        (match) =>
            match.status != 'finalizado' && match.status != 'em_andamento',
      )
      .length;

  List<ViewerMatchModel> get _filteredMatches {
    switch (_selectedFilter) {
      case 'live':
        return _matches
            .where((match) => match.status == 'em_andamento')
            .toList();
      case 'finished':
        return _matches
            .where((match) => match.status == 'finalizado')
            .toList();
      case 'upcoming':
        return _matches
            .where(
              (match) =>
                  match.status != 'finalizado' &&
                  match.status != 'em_andamento',
            )
            .toList();
      case 'all':
      default:
        return _matches;
    }
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
    return 'Agendado';
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

  Widget _buildSummaryChip(String label, String value, Color color) {
    final selected =
        (_selectedFilter == 'all' && label == 'Todos') ||
        (_selectedFilter == 'live' && label == 'Ao vivo') ||
        (_selectedFilter == 'finished' && label == 'Finalizado') ||
        (_selectedFilter == 'upcoming' && label == 'Proximos');

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          switch (label) {
            case 'Ao vivo':
              _selectedFilter = 'live';
              break;
            case 'Finalizado':
              _selectedFilter = 'finished';
              break;
            case 'Proximos':
              _selectedFilter = 'upcoming';
              break;
            default:
              _selectedFilter = 'all';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.24)
              : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: selected
              ? Border.all(color: color.withValues(alpha: 0.50))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  '${widget.competition.category} • ${widget.competition.gender} • ${widget.competition.year}',
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
                                    _buildSummaryChip(
                                      'Todos',
                                      '${_matches.length}',
                                      Colors.white70,
                                    ),
                                    _buildSummaryChip(
                                      'Ao vivo',
                                      '$_liveCount',
                                      const Color(0xFFFF5B5B),
                                    ),
                                    _buildSummaryChip(
                                      'Finalizado',
                                      '$_finishedCount',
                                      const Color(0xFFB0BEC5),
                                    ),
                                    _buildSummaryChip(
                                      'Proximos',
                                      '$_upcomingCount',
                                      const Color(0xFF4FC3F7),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171C23),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: _filteredMatches.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'Nenhuma partida encontrada nesse filtro.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (var i = 0; i < _filteredMatches.length; i++) ...[
                                        _buildMatchRow(_filteredMatches[i]),
                                        if (i != _filteredMatches.length - 1)
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
