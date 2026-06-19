import 'package:flutter/material.dart';

import '../../models/player_model.dart';
import '../../models/viewer_match_model.dart';
import '../../repositories/match_event_repository.dart';
import '../../repositories/match_statistics_repository.dart';
import '../../repositories/player_repository.dart';
import '../../repositories/shot_event_repository.dart';
import '../../repositories/viewer_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/athlete_photo_avatar.dart';

class ViewerMatchDetailPage extends StatefulWidget {
  final ViewerMatchModel match;

  const ViewerMatchDetailPage({
    super.key,
    required this.match,
  });

  @override
  State<ViewerMatchDetailPage> createState() => _ViewerMatchDetailPageState();
}

class _ViewerMatchDetailPageState extends State<ViewerMatchDetailPage> {
  final _viewerRepository = ViewerRepository();
  final _statsRepository = MatchStatisticsRepository();
  final _playerRepository = PlayerRepository();
  final _shotEventRepository = ShotEventRepository();
  final _matchEventRepository = MatchEventRepository();

  bool _isLoading = true;
  String? _errorMessage;
  ViewerMatchModel? _match;
  List<Map<String, dynamic>> _liveStats = [];
  List<Map<String, dynamic>> _goalkeeperStats = [];
  List<Map<String, dynamic>> _playerStats = [];
  List<Map<String, dynamic>> _shotEvents = [];
  List<Map<String, dynamic>> _matchEvents = [];
  Map<String, String?> _playerPhotoUrls = {};
  Map<String, String> _playerNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _viewerRepository.getMatchById(widget.match.id),
        _statsRepository.getMatchLiveStats(widget.match.id),
        _statsRepository.getMatchGoalkeeperStats(widget.match.id),
        _statsRepository.getMatchPlayerStats(widget.match.id),
        _shotEventRepository.getMatchEvents(widget.match.id),
        _matchEventRepository.getMatchEvents(widget.match.id),
        _playerRepository.getPlayers(),
      ]);

      final allPlayers = results[6] as List<PlayerModel>;
      final photoMap = <String, String?>{};
      final playerNames = <String, String>{};
      for (final player in allPlayers) {
        photoMap[player.id] = player.photoUrl;
        playerNames[player.id] = player.fullName;
      }

      if (!mounted) return;

      setState(() {
        _match = results[0] as ViewerMatchModel? ?? widget.match;
        _liveStats = results[1] as List<Map<String, dynamic>>;
        _goalkeeperStats = results[2] as List<Map<String, dynamic>>;
        _playerStats = results[3] as List<Map<String, dynamic>>;
        _shotEvents = results[4] as List<Map<String, dynamic>>;
        _matchEvents = results[5] as List<Map<String, dynamic>>;
        _playerPhotoUrls = photoMap;
        _playerNames = playerNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar partida: $e';
        _isLoading = false;
      });
    }
  }

  ViewerMatchModel get _currentMatch => _match ?? widget.match;

  Map<String, dynamic>? _findStats(String teamId) {
    try {
      return _liveStats.firstWhere((item) => item['team_id'] == teamId);
    } catch (_) {
      return null;
    }
  }

  String? _photoUrlForAthlete(Map<String, dynamic> athlete) {
    final playerId = athlete['player_id'] as String?;
    if (playerId == null) return null;
    return _playerPhotoUrls[playerId];
  }

  String _fmt(dynamic value) => '${value ?? 0}';

  int _countShotsByResult(String teamId, String result) {
    return _shotEvents.where((item) {
      return item['team_id'] == teamId && item['shot_result'] == result;
    }).length;
  }

  String _playerName(String? playerId) {
    if (playerId == null) return 'Jogador';
    return _playerNames[playerId] ?? 'Jogador';
  }

  String _teamName(String? teamId) {
    final match = _currentMatch;
    if (teamId == match.homeTeamId) return match.homeTeamName;
    if (teamId == match.awayTeamId) return match.awayTeamName;
    return 'Time';
  }

  Color _teamAccent(String? teamId) {
    final match = _currentMatch;
    if (teamId == match.homeTeamId) return AppThemeColors.secondary;
    if (teamId == match.awayTeamId) return AppThemeColors.accent;
    return Colors.white70;
  }

  String _headerStatus() {
    final match = _currentMatch;

    if (match.status == 'em_andamento') {
      final minute = (match.currentMinute ?? 0).toString().padLeft(2, '0');
      final second = (match.currentSecond ?? 0).toString().padLeft(2, '0');
      return '$minute:$second';
    }

    if (match.status == 'finalizado') {
      return 'Finalizado';
    }

    if (match.matchDatetime == null || match.matchDatetime!.isEmpty) {
      return 'Agendado';
    }

    final parsed = DateTime.tryParse(match.matchDatetime!);
    if (parsed == null) return 'Agendado';

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  String _periodLabel() {
    final period = _currentMatch.currentPeriod?.toLowerCase();
    if (period == null || period.isEmpty) return '';
    if (period.contains('1')) return '1o tempo';
    if (period.contains('2')) return '2o tempo';
    if (period.contains('interval')) return 'Intervalo';
    if (period.contains('pror')) return 'Prorrogacao';
    return _currentMatch.currentPeriod ?? '';
  }

  Widget _buildShield(String? url, {double size = 88}) {
    return SizedBox(
      width: size,
      height: size,
      child: url == null || url.isEmpty
          ? Icon(
              Icons.shield_outlined,
              size: size * 0.72,
              color: Colors.white70,
            )
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.shield_outlined,
                size: size * 0.72,
                color: Colors.white70,
              ),
            ),
    );
  }

  Widget _darkSurface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF171C23),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }

  List<Map<String, dynamic>> _topPlayersByTeam(String teamId) {
    final items = _playerStats
        .where((item) => item['team_id'] == teamId)
        .toList();

    items.sort((a, b) {
      final goalCompare = ((b['goals'] as num?) ?? 0)
          .compareTo((a['goals'] as num?) ?? 0);
      if (goalCompare != 0) return goalCompare;
      return ((b['shot_percentage'] as num?) ?? 0)
          .compareTo((a['shot_percentage'] as num?) ?? 0);
    });

    return items.take(2).toList();
  }

  Map<String, dynamic>? _topGoalkeeperByTeam(String teamId) {
    final items = _goalkeeperStats
        .where((item) => item['team_id'] == teamId)
        .toList();

    if (items.isEmpty) return null;

    items.sort((a, b) {
      final saveCompare = ((b['saves'] as num?) ?? 0)
          .compareTo((a['saves'] as num?) ?? 0);
      if (saveCompare != 0) return saveCompare;
      return ((b['save_percentage'] as num?) ?? 0)
          .compareTo((a['save_percentage'] as num?) ?? 0);
    });

    return items.first;
  }

  List<Map<String, dynamic>> _timelineItems() {
    final items = <Map<String, dynamic>>[];

    for (final shot in _shotEvents) {
      items.add({
        'kind': 'shot',
        'team_id': shot['team_id'],
        'player_id': shot['player_id'],
        'event_type': shot['shot_result'],
        'minute': shot['minute'],
        'second': shot['second'],
        'sequence_order': shot['sequence_order'],
      });
    }

    for (final event in _matchEvents) {
      items.add({
        'kind': 'match',
        'team_id': event['team_id'],
        'player_id': event['player_id'],
        'event_type': event['event_type'],
        'minute': event['minute'],
        'second': event['second'],
        'sequence_order': event['sequence_order'],
      });
    }

    items.sort((a, b) {
      final aOrder = (a['sequence_order'] as int?) ?? 0;
      final bOrder = (b['sequence_order'] as int?) ?? 0;
      return bOrder.compareTo(aOrder);
    });

    return items;
  }

  String _timelineTitle(Map<String, dynamic> item) {
    final type = item['event_type'] as String? ?? '';
    switch (type) {
      case 'goal':
        return 'Gol';
      case 'saved':
        return 'Defesa do goleiro';
      case 'post':
        return 'Arremesso na trave';
      case 'out':
        return 'Arremesso para fora';
      case 'blocked':
        return 'Arremesso bloqueado';
      case 'yellow_card':
        return 'Cartao amarelo';
      case 'red_card':
        return 'Cartao vermelho';
      case 'blue_card':
        return 'Cartao azul';
      case 'suspension_2min':
        return 'Suspensao de 2 min';
      case 'timeout':
        return 'Timeout';
      default:
        return 'Evento';
    }
  }

  IconData _timelineIcon(Map<String, dynamic> item) {
    final type = item['event_type'] as String? ?? '';
    switch (type) {
      case 'goal':
        return Icons.sports_score_rounded;
      case 'saved':
        return Icons.front_hand_outlined;
      case 'post':
        return Icons.crop_3_2_outlined;
      case 'out':
        return Icons.north_east_rounded;
      case 'blocked':
        return Icons.block_outlined;
      case 'yellow_card':
        return Icons.style_rounded;
      case 'red_card':
        return Icons.square_rounded;
      case 'blue_card':
        return Icons.crop_square_rounded;
      case 'suspension_2min':
        return Icons.timer_outlined;
      case 'timeout':
        return Icons.pause_circle_outline;
      default:
        return Icons.bolt_rounded;
    }
  }

  String _timelineClock(Map<String, dynamic> item) {
    final minute = ((item['minute'] as int?) ?? 0).toString().padLeft(2, '0');
    final second = ((item['second'] as int?) ?? 0).toString().padLeft(2, '0');
    return '$minute:$second';
  }

  Widget _buildHeader() {
    final match = _currentMatch;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF12171D),
            Color(0xFF1C232C),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Text(
            match.competitionName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildShield(match.homeTeamShieldUrl),
                    const SizedBox(height: 10),
                    Text(
                      match.homeTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    Text(
                      '${match.scoreHome} - ${match.scoreAway}',
                      style: const TextStyle(
                        color: Color(0xFFFF5B5B),
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _headerStatus(),
                      style: TextStyle(
                        color: match.status == 'em_andamento'
                            ? const Color(0xFFFF5B5B)
                            : Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    if (_periodLabel().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _periodLabel(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildShield(match.awayTeamShieldUrl),
                    const SizedBox(height: 10),
                    Text(
                      match.awayTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralStatsCard() {
    final match = _currentMatch;
    final homeStats = _findStats(match.homeTeamId);
    final awayStats = _findStats(match.awayTeamId);

    Widget statRow(String label, dynamic left, dynamic right) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _fmt(left),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Expanded(
              child: Text(
                _fmt(right),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _darkSurface(
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Estatisticas gerais',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          statRow('Chutes', homeStats?['shots'], awayStats?['shots']),
          statRow(
            'Aproveitamento %',
            homeStats?['shot_percentage'],
            awayStats?['shot_percentage'],
          ),
          statRow('Gols 9M', homeStats?['goals_9m'], awayStats?['goals_9m']),
          statRow(
            'Aprov. 9M %',
            homeStats?['shot_percentage_9m'],
            awayStats?['shot_percentage_9m'],
          ),
          statRow('Gols 7M', homeStats?['goals_7m'], awayStats?['goals_7m']),
          statRow(
            'Aprov. 7M %',
            homeStats?['shot_percentage_7m'],
            awayStats?['shot_percentage_7m'],
          ),
          statRow(
            'Gols Contra-Ataque',
            homeStats?['counter_attack_goals'],
            awayStats?['counter_attack_goals'],
          ),
          statRow('Fora', homeStats?['shots_out'], awayStats?['shots_out']),
          statRow(
            'Trave',
            _countShotsByResult(match.homeTeamId, 'post'),
            _countShotsByResult(match.awayTeamId, 'post'),
          ),
          statRow(
            'Defesas sofridas',
            homeStats?['shots_saved'],
            awayStats?['shots_saved'],
          ),
          statRow(
            'Bloqueados',
            homeStats?['shots_blocked'],
            awayStats?['shots_blocked'],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    final timeline = _timelineItems();

    return _darkSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline da partida',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          if (timeline.isEmpty)
            Text(
              'Ainda nao ha eventos publicados nessa partida.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < timeline.length; i++) ...[
                  _buildTimelineRow(timeline[i]),
                  if (i != timeline.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(Map<String, dynamic> item) {
    final teamAccent = _teamAccent(item['team_id'] as String?);
    final playerName = _playerName(item['player_id'] as String?);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E252F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              _timelineClock(item),
              style: TextStyle(
                color: teamAccent,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: teamAccent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              _timelineIcon(item),
              color: teamAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _timelineTitle(item),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  playerName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _teamName(item['team_id'] as String?),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHighlightRow({
    required Map<String, dynamic> player,
    required String badge,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E252F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          AthletePhotoAvatar(
            photoUrl: _photoUrlForAthlete(player),
            size: 56,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['player_name'] as String? ?? 'Jogador',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'G/Arremesso -> ${_fmt(player['goals'])}/${_fmt(player['shots'])}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalkeeperRow({
    required Map<String, dynamic> goalkeeper,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E252F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.front_hand_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          AthletePhotoAvatar(
            photoUrl: _photoUrlForAthlete(goalkeeper),
            size: 56,
            fallbackIcon: Icons.sports_handball,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goalkeeper['goalkeeper_name'] as String? ?? 'Goleiro',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Defesas/Arremessos -> ${_fmt(goalkeeper['saves'])}/${_fmt(goalkeeper['shots_faced'])}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHighlightsPanel({
    required String title,
    required List<Map<String, dynamic>> players,
    required Map<String, dynamic>? goalkeeper,
    required Color accent,
  }) {
    return _darkSurface(
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 12),
          if (players.isEmpty && goalkeeper == null)
            Text(
              'Sem destaques disponiveis para esse time.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < players.length; i++) ...[
                  _buildPlayerHighlightRow(
                    player: players[i],
                    badge: '${i + 1}',
                    accent: accent,
                  ),
                  const SizedBox(height: 12),
                ],
                if (goalkeeper != null)
                  _buildGoalkeeperRow(
                    goalkeeper: goalkeeper,
                    accent: accent,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    final match = _currentMatch;
    final homeTopPlayers = _topPlayersByTeam(match.homeTeamId);
    final awayTopPlayers = _topPlayersByTeam(match.awayTeamId);
    final homeGoalkeeper = _topGoalkeeperByTeam(match.homeTeamId);
    final awayGoalkeeper = _topGoalkeeperByTeam(match.awayTeamId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Destaques da partida',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        if (homeTopPlayers.isEmpty &&
            awayTopPlayers.isEmpty &&
            homeGoalkeeper == null &&
            awayGoalkeeper == null)
          _darkSurface(
            child: Text(
              'Ainda nao ha destaques disponiveis nessa partida.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 860;

              if (compact) {
                return Column(
                  children: [
                    _buildTeamHighlightsPanel(
                      title: match.homeTeamName,
                      players: homeTopPlayers,
                      goalkeeper: homeGoalkeeper,
                      accent: AppThemeColors.secondary,
                    ),
                    const SizedBox(height: 14),
                    _buildTeamHighlightsPanel(
                      title: match.awayTeamName,
                      players: awayTopPlayers,
                      goalkeeper: awayGoalkeeper,
                      accent: AppThemeColors.accent,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTeamHighlightsPanel(
                      title: match.homeTeamName,
                      players: homeTopPlayers,
                      goalkeeper: homeGoalkeeper,
                      accent: AppThemeColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTeamHighlightsPanel(
                      title: match.awayTeamName,
                      players: awayTopPlayers,
                      goalkeeper: awayGoalkeeper,
                      accent: AppThemeColors.accent,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1016),
      appBar: AppBar(
        title: const Text('Partida'),
        backgroundColor: const Color(0xFF0B1016),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFF0B1016),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 18),
                            _buildGeneralStatsCard(),
                            const SizedBox(height: 18),
                            _buildTimelineSection(),
                            const SizedBox(height: 18),
                            _buildHighlightsSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
