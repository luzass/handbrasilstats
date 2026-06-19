import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/match_model.dart';
import '../../repositories/match_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import 'match_form_page.dart';
import 'match_players_page.dart';

class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key});

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  final _repository = MatchRepository();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  List<MatchModel> _matches = [];

  Map<String, String> _competitionNames = {};
  Map<String, String> _teamNames = {};
  Map<String, String?> _teamShields = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final matches = await _repository.getMatches();

      final competitionsResponse = await _supabase
          .from('competitions')
          .select('id, name');

      final teamsResponse = await _supabase
          .from('teams')
          .select('id, name, shield_url');

      final competitionMap = <String, String>{};
      for (final item in competitionsResponse) {
        competitionMap[item['id'] as String] = item['name'] as String;
      }

      final teamMap = <String, String>{};
      final shieldMap = <String, String?>{};
      for (final item in teamsResponse) {
        teamMap[item['id'] as String] = item['name'] as String;
        shieldMap[item['id'] as String] = item['shield_url'] as String?;
      }

      if (!mounted) return;

      setState(() {
        _matches = matches;
        _competitionNames = competitionMap;
        _teamNames = teamMap;
        _teamShields = shieldMap;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar partidas: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openForm([MatchModel? match]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchFormPage(match: match),
      ),
    );

    await _loadAll();
  }

  String _competitionLabel(String id) => _competitionNames[id] ?? id;
  String _teamLabel(String id) => _teamNames[id] ?? id;

  Map<String, List<MatchModel>> _groupMatchesByCompetition() {
    final grouped = <String, List<MatchModel>>{};

    for (final match in _matches) {
      grouped.putIfAbsent(match.competitionId, () => []).add(match);
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => _competitionLabel(a.key).compareTo(_competitionLabel(b.key)));

    return {
      for (final entry in sortedEntries) entry.key: entry.value,
    };
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'Sem data';

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return 'Sem data';

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month - $hour:$minute';
  }

  Widget _statusChip(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _teamShield(String? url) {
    return SizedBox(
      width: 34,
      height: 34,
      child: url == null || url.isEmpty
          ? const Icon(
              Icons.shield_outlined,
              color: AppThemeColors.primary,
              size: 22,
            )
          : Image.network(
              url,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.shield_outlined,
                color: AppThemeColors.primary,
                size: 22,
              ),
            ),
    );
  }

  Widget _buildCompetitionSection(String competitionId, List<MatchModel> matches) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _competitionLabel(competitionId),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < matches.length; i++) ...[
              _buildMatchRow(matches[i]),
              if (i != matches.length - 1) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchRow(MatchModel item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;

        final timeColumn = SizedBox(
          width: compact ? 88 : 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(item.matchDatetime),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppThemeColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              _statusChip(
                item.status,
                const Color(0xFFE7F3EE),
                AppThemeColors.primary,
              ),
            ],
          ),
        );

        final teamsBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _teamShield(_teamShields[item.homeTeamId]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _teamLabel(item.homeTeamId),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${item.scoreHome}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _teamShield(_teamShields[item.awayTeamId]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _teamLabel(item.awayTeamId),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${item.scoreAway}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(
                  'Scout: ${item.scoutStatus}',
                  const Color(0xFFEAF1FB),
                  AppThemeColors.info,
                ),
              ],
            ),
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MatchPlayersPage(match: item),
                  ),
                );
              },
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Elenco'),
            ),
            TextButton.icon(
              onPressed: () => _openForm(item),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              timeColumn,
              const SizedBox(height: 14),
              teamsBlock,
              const SizedBox(height: 14),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            timeColumn,
            const SizedBox(width: 18),
            Expanded(child: teamsBlock),
            const SizedBox(width: 18),
            SizedBox(
              width: 190,
              child: Align(
                alignment: Alignment.topRight,
                child: actions,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedMatches = _groupMatchesByCompetition();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidas'),
        actions: [
          IconButton(
            onPressed: () => _openForm(),
            tooltip: 'Adicionar jogo',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AppBackdrop(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _matches.isEmpty
                    ? const Center(child: Text('Nenhuma partida cadastrada.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedMatches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final entry = groupedMatches.entries.elementAt(index);
                          return _buildCompetitionSection(
                            entry.key,
                            entry.value,
                          );
                        },
                      ),
      ),
    );
  }
}
