
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/match_event_model.dart';
import '../../models/match_model.dart';
import '../../models/shot_event_model.dart';
import '../../repositories/match_event_repository.dart';
import '../../repositories/match_live_stats_repository.dart';
import '../../repositories/shot_event_repository.dart';
import '../../widgets/goal_zone_selector.dart';
import '../../widgets/shot_zone_selector.dart';
import 'edit_match_event_page.dart';
import 'edit_shot_event_page.dart';

class LiveScoutPage extends StatefulWidget {
  final MatchModel match;

  const LiveScoutPage({
    super.key,
    required this.match,
  });

  @override
  State<LiveScoutPage> createState() => _LiveScoutPageState();
}

class _ShotDraft {
  final String? playerId;
  final int? zoneId;
  final int? goalZoneId;
  final String result;
  final String attackContext;

  const _ShotDraft({
    this.playerId,
    this.zoneId,
    this.goalZoneId,
    this.result = 'goal',
    this.attackContext = 'normal',
  });

  _ShotDraft copyWith({
    String? playerId,
    bool clearPlayerId = false,
    int? zoneId,
    bool clearZoneId = false,
    int? goalZoneId,
    bool clearGoalZoneId = false,
    String? result,
    String? attackContext,
  }) {
    return _ShotDraft(
      playerId: clearPlayerId ? null : (playerId ?? this.playerId),
      zoneId: clearZoneId ? null : (zoneId ?? this.zoneId),
      goalZoneId: clearGoalZoneId ? null : (goalZoneId ?? this.goalZoneId),
      result: result ?? this.result,
      attackContext: attackContext ?? this.attackContext,
    );
  }
}

class _LiveScoutPageState extends State<LiveScoutPage> {
  final _supabase = Supabase.instance.client;
  final _shotRepository = ShotEventRepository();
  final _matchEventRepository = MatchEventRepository();
  final _matchLiveStatsRepository = MatchLiveStatsRepository();
  final FocusNode _pageFocusNode = FocusNode();

  Timer? _timer;
  Timer? _shotRefreshTimer;
  Timer? _genericRefreshTimer;

  bool _isLoading = true;
  bool _isSavingLeft = false;
  bool _isSavingRight = false;
  bool _isSavingLeftMatchEvent = false;
  bool _isSavingRightMatchEvent = false;
  bool _isClockRunning = false;
  bool _isDeletingEvent = false;
  String? _errorMessage;

  int _scoreHome = 0;
  int _scoreAway = 0;

  String _currentPeriod = 'first_half';
  int _currentMinute = 0;
  int _currentSecond = 0;

  Map<String, String> _teamNames = {};
  Map<String, String?> _teamShields = {};
  Map<String, String> _playerNames = {};

  List<Map<String, dynamic>> _homePlayers = [];
  List<Map<String, dynamic>> _awayPlayers = [];
  List<Map<String, dynamic>> _homeGoalkeepers = [];
  List<Map<String, dynamic>> _awayGoalkeepers = [];
  List<Map<String, dynamic>> _shotEventHistory = [];
  List<Map<String, dynamic>> _matchEventHistory = [];
  List<Map<String, dynamic>> _liveStats = [];

  String? _currentHomeGoalkeeperId;
  String? _currentAwayGoalkeeperId;

  final ValueNotifier<_ShotDraft> _leftShotDraft = ValueNotifier(const _ShotDraft());
  final ValueNotifier<_ShotDraft> _rightShotDraft = ValueNotifier(const _ShotDraft());

  String? _leftMatchEventPlayerId;
  String _leftMatchEventType = 'suspension_2min';

  String? _rightMatchEventPlayerId;
  String _rightMatchEventType = 'suspension_2min';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shotRefreshTimer?.cancel();
    _genericRefreshTimer?.cancel();
    _pageFocusNode.dispose();
    _leftShotDraft.dispose();
    _rightShotDraft.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final teamsResponse = await _supabase
    .from('teams')
    .select('id, name, shield_url');

      final playersResponse = await _supabase.from('players').select('id, full_name');

      final matchPlayersResponse = await _supabase
          .from('match_players')
          .select(
            'player_id, team_id, is_goalkeeper, shirt_number, players(id, full_name)',
          )
          .eq('match_id', widget.match.id)
          .eq('is_active_in_match', true);

      final matchResponse = await _supabase
          .from('matches')
          .select('score_home, score_away, current_period, current_minute, current_second')
          .eq('id', widget.match.id)
          .single();

      final shotEventHistory = await _shotRepository.getMatchEvents(widget.match.id);
      final matchEventHistory = await _matchEventRepository.getMatchEvents(widget.match.id);
      final liveStats = await _matchLiveStatsRepository.getMatchLiveStats(widget.match.id);

      final teamMap = <String, String>{};
      final shieldMap = <String, String?>{};
      for (final item in teamsResponse) {
        teamMap[item['id'] as String] = item['name'] as String;
        shieldMap[item['id'] as String] = item['shield_url'] as String?;
      }

      final playerMap = <String, String>{};
      for (final item in playersResponse) {
        playerMap[item['id'] as String] = item['full_name'] as String;
      }

      final homePlayers = <Map<String, dynamic>>[];
      final awayPlayers = <Map<String, dynamic>>[];
      final homeGoalkeepers = <Map<String, dynamic>>[];
      final awayGoalkeepers = <Map<String, dynamic>>[];

      for (final item in matchPlayersResponse) {
        final player = item['players'];
        if (player == null) continue;

        final shirtNumber = item['shirt_number'] as int?;
        if (shirtNumber == null) {
          continue;
        }

        final row = {
          'id': player['id'] as String,
          'full_name': player['full_name'] as String,
          'team_id': item['team_id'] as String,
          'is_goalkeeper': item['is_goalkeeper'] as bool? ?? false,
          'shirt_number': shirtNumber,
        };

        final isGoalkeeper = row['is_goalkeeper'] as bool;
        final teamId = row['team_id'] as String;

        if (teamId == widget.match.homeTeamId) {
          if (isGoalkeeper) {
            homeGoalkeepers.add(row);
          } else {
            homePlayers.add(row);
          }
        } else if (teamId == widget.match.awayTeamId) {
          if (isGoalkeeper) {
            awayGoalkeepers.add(row);
          } else {
            awayPlayers.add(row);
          }
        }
      }

      homePlayers.sort((a, b) {
        final aNum = (a['shirt_number'] as int?) ?? 999;
        final bNum = (b['shirt_number'] as int?) ?? 999;
        return aNum.compareTo(bNum);
      });

      awayPlayers.sort((a, b) {
        final aNum = (a['shirt_number'] as int?) ?? 999;
        final bNum = (b['shirt_number'] as int?) ?? 999;
        return aNum.compareTo(bNum);
      });

      if (!mounted) return;

      setState(() {
        _teamNames = teamMap;
        _teamShields = shieldMap;
        _playerNames = playerMap;
        _homePlayers = homePlayers;
        _awayPlayers = awayPlayers;
        _homeGoalkeepers = homeGoalkeepers;
        _awayGoalkeepers = awayGoalkeepers;
        _shotEventHistory = shotEventHistory;
        _matchEventHistory = matchEventHistory;
        _liveStats = liveStats;
        _currentHomeGoalkeeperId =
            homeGoalkeepers.isNotEmpty ? homeGoalkeepers.first['id'] as String : null;
        _currentAwayGoalkeeperId =
            awayGoalkeepers.isNotEmpty ? awayGoalkeepers.first['id'] as String : null;
        _scoreHome = matchResponse['score_home'] as int? ?? 0;
        _scoreAway = matchResponse['score_away'] as int? ?? 0;
        _currentPeriod = (matchResponse['current_period'] as String?) ?? 'first_half';
        _currentMinute = matchResponse['current_minute'] as int? ?? 0;
        _currentSecond = matchResponse['current_second'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados do scout: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _findTeamStats(String teamId) {
    try {
      return _liveStats.firstWhere((item) => item['team_id'] == teamId);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchScoreboard() async {
    try {
      final response = await _supabase
          .from('matches')
          .select('score_home, score_away')
          .eq('id', widget.match.id)
          .single();

      return Map<String, dynamic>.from(response);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchShotEventHistory() async {
    try {
      return await _shotRepository.getMatchEvents(widget.match.id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchMatchEventHistory() async {
    try {
      return await _matchEventRepository.getMatchEvents(widget.match.id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchLiveStats() async {
    try {
      return await _matchLiveStatsRepository.getMatchLiveStats(widget.match.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncClockToMatch() async {
    try {
      await _supabase.from('matches').update({
        'current_period': _currentPeriod,
        'current_minute': _currentMinute,
        'current_second': _currentSecond,
      }).eq('id', widget.match.id);
    } catch (_) {}
  }

  Future<void> _refreshAfterShotMutation() async {
    final results = await Future.wait([
      _fetchScoreboard(),
      _fetchShotEventHistory(),
      _fetchLiveStats(),
    ]);

    if (!mounted) return;

    final scoreboard = results[0] as Map<String, dynamic>?;
    final shotHistory = results[1] as List<Map<String, dynamic>>?;
    final liveStats = results[2] as List<Map<String, dynamic>>?;

    setState(() {
      if (scoreboard != null) {
        _scoreHome = scoreboard['score_home'] as int? ?? _scoreHome;
        _scoreAway = scoreboard['score_away'] as int? ?? _scoreAway;
      }
      if (shotHistory != null) {
        _shotEventHistory = shotHistory;
      }
      if (liveStats != null) {
        _liveStats = liveStats;
      }
    });
  }

  Future<void> _refreshAfterGenericMutation() async {
    final history = await _fetchMatchEventHistory();
    if (!mounted || history == null) return;

    setState(() {
      _matchEventHistory = history;
    });
  }

  void _scheduleShotRefresh({Duration delay = const Duration(milliseconds: 250)}) {
    _shotRefreshTimer?.cancel();
    _shotRefreshTimer = Timer(delay, () {
      unawaited(_refreshAfterShotMutation());
    });
  }

  void _scheduleGenericRefresh({Duration delay = const Duration(milliseconds: 250)}) {
    _genericRefreshTimer?.cancel();
    _genericRefreshTimer = Timer(delay, () {
      unawaited(_refreshAfterGenericMutation());
    });
  }

  int _nextShotSequenceOrderLocal() {
    if (_shotEventHistory.isEmpty) return 1;
    final currentMax = _shotEventHistory
        .map((item) => item['sequence_order'] as int? ?? 0)
        .fold<int>(0, math.max);
    return currentMax + 1;
  }

  int _nextGenericSequenceOrderLocal() {
    if (_matchEventHistory.isEmpty) return 1;
    final currentMax = _matchEventHistory
        .map((item) => item['sequence_order'] as int? ?? 0)
        .fold<int>(0, math.max);
    return currentMax + 1;
  }

  void _optimisticallyApplyShotEvent(ShotEventModel event) {
    final tempId = 'local-shot-${DateTime.now().microsecondsSinceEpoch}';
    final eventMap = {
      'id': tempId,
      ...event.toInsertMap(),
    };

    setState(() {
      _shotEventHistory = [eventMap, ..._shotEventHistory];
      if (event.shotResult == 'goal') {
        if (event.teamId == widget.match.homeTeamId) {
          _scoreHome += 1;
        } else if (event.teamId == widget.match.awayTeamId) {
          _scoreAway += 1;
        }
      }
    });
  }

  void _optimisticallyApplyGenericEvent(MatchEventModel event) {
    final tempId = 'local-match-${DateTime.now().microsecondsSinceEpoch}';
    final eventMap = {
      'id': tempId,
      ...event.toInsertMap(),
    };

    setState(() {
      _matchEventHistory = [eventMap, ..._matchEventHistory];
    });
  }

  Future<void> _deleteShotEvent(String eventId) async {
    setState(() {
      _isDeletingEvent = true;
      _errorMessage = null;
    });

    try {
      await _shotRepository.deleteShotEvent(eventId);
      await _refreshAfterShotMutation();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento de chute desfeito com sucesso.')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao desfazer evento: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingEvent = false;
        });
      }
    }
  }

  Future<void> _deleteGenericEvent(String eventId) async {
    setState(() {
      _isDeletingEvent = true;
      _errorMessage = null;
    });

    try {
      await _matchEventRepository.deleteMatchEvent(eventId);
      await _refreshAfterGenericMutation();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento da partida desfeito com sucesso.')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao desfazer evento da partida: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingEvent = false;
        });
      }
    }
  }

  Future<void> _editShotEvent(Map<String, dynamic> event) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditShotEventPage(
          event: event,
          teamNames: _teamNames,
          playerNames: _playerNames,
          homePlayers: _homePlayers,
          awayPlayers: _awayPlayers,
          homeGoalkeepers: _homeGoalkeepers,
          awayGoalkeepers: _awayGoalkeepers,
          homeTeamId: widget.match.homeTeamId,
          awayTeamId: widget.match.awayTeamId,
        ),
      ),
    );

    if (result == true) {
      _scheduleShotRefresh(delay: Duration.zero);
    }
  }

  Future<void> _editGenericEvent(Map<String, dynamic> event) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditMatchEventPage(
          event: event,
          teamNames: _teamNames,
          playerNames: _playerNames,
          homePlayers: _homePlayers,
          awayPlayers: _awayPlayers,
          homeGoalkeepers: _homeGoalkeepers,
          awayGoalkeepers: _awayGoalkeepers,
          homeTeamId: widget.match.homeTeamId,
          awayTeamId: widget.match.awayTeamId,
        ),
      ),
    );

    if (result == true) {
      _scheduleGenericRefresh(delay: Duration.zero);
    }
  }

  void _toggleClock() {
    if (_isClockRunning) {
      _timer?.cancel();
      setState(() {
        _isClockRunning = false;
      });
      _syncClockToMatch();
      return;
    }

    setState(() {
      _isClockRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _currentSecond++;
        if (_currentSecond >= 60) {
          _currentSecond = 0;
          _currentMinute++;
        }
      });
    });
  }

  void _resetClock() {
    _timer?.cancel();
    setState(() {
      _isClockRunning = false;
      _currentMinute = 0;
      _currentSecond = 0;
    });
    _syncClockToMatch();
  }

  void _changePeriod(String period) {
    setState(() {
      _currentPeriod = period;
    });
    _syncClockToMatch();
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'first_half':
        return '1º tempo';
      case 'second_half':
        return '2º tempo';
      case 'extra_time_1':
        return 'Prorrogação 1';
      case 'extra_time_2':
        return 'Prorrogação 2';
      case 'penalties':
        return 'Tiros';
      default:
        return period;
    }
  }

  String _formattedClock() {
    final mm = _currentMinute.toString().padLeft(2, '0');
    final ss = _currentSecond.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  bool _goalZoneIsRequired(String result) {
    return result == 'goal' || result == 'saved';
  }

  bool _attackContextApplies(String result) {
    return result == 'goal';
  }

  bool _leftGenericNeedsPlayer() {
    return _leftMatchEventType != 'timeout';
  }

  bool _rightGenericNeedsPlayer() {
    return _rightMatchEventType != 'timeout';
  }

  KeyEventResult _handleScoutHotkeys(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyP) {
      _toggleClock();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _saveLeftEvent() async {
    final draft = _leftShotDraft.value;
    final previousHistory = List<Map<String, dynamic>>.from(_shotEventHistory);
    final previousScoreHome = _scoreHome;
    final previousScoreAway = _scoreAway;

    if (draft.playerId == null || draft.zoneId == null) {
      setState(() {
        _errorMessage = 'Preencha jogador e zona do time da esquerda.';
      });
      return;
    }

    if (_goalZoneIsRequired(draft.result) && draft.goalZoneId == null) {
      setState(() {
        _errorMessage = 'Selecione a zona do gol do time da esquerda.';
      });
      return;
    }

    setState(() {
      _isSavingLeft = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      final sequence = _nextShotSequenceOrderLocal();

      final event = ShotEventModel(
        id: '',
        matchId: widget.match.id,
        competitionId: widget.match.competitionId,
        teamId: widget.match.homeTeamId,
        playerId: draft.playerId!,
        goalkeeperPlayerId: _currentAwayGoalkeeperId,
        zoneId: draft.zoneId!,
        goalZoneId: _goalZoneIsRequired(draft.result) ? draft.goalZoneId : null,
        shotType: draft.zoneId == 11 ? 'seven_meter' : 'open_play',
        shotResult: draft.result,
        attackContext: _attackContextApplies(draft.result)
            ? draft.attackContext
            : 'normal',
        period: _currentPeriod,
        minute: _currentMinute,
        second: _currentSecond,
        sequenceOrder: sequence,
        createdBy: user?.id,
        notes: null,
      );

      _optimisticallyApplyShotEvent(event);

      await _shotRepository.createShotEvent(event);

      if (!mounted) return;

      _leftShotDraft.value = const _ShotDraft();
      _scheduleShotRefresh();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar evento: $e';
        _shotEventHistory = previousHistory;
        _scoreHome = previousScoreHome;
        _scoreAway = previousScoreAway;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingLeft = false;
        });
      }
    }
  }

  Future<void> _saveRightEvent() async {
    final draft = _rightShotDraft.value;
    final previousHistory = List<Map<String, dynamic>>.from(_shotEventHistory);
    final previousScoreHome = _scoreHome;
    final previousScoreAway = _scoreAway;

    if (draft.playerId == null || draft.zoneId == null) {
      setState(() {
        _errorMessage = 'Preencha jogador e zona do time da direita.';
      });
      return;
    }

    if (_goalZoneIsRequired(draft.result) && draft.goalZoneId == null) {
      setState(() {
        _errorMessage = 'Selecione a zona do gol do time da direita.';
      });
      return;
    }

    setState(() {
      _isSavingRight = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      final sequence = _nextShotSequenceOrderLocal();

      final event = ShotEventModel(
        id: '',
        matchId: widget.match.id,
        competitionId: widget.match.competitionId,
        teamId: widget.match.awayTeamId,
        playerId: draft.playerId!,
        goalkeeperPlayerId: _currentHomeGoalkeeperId,
        zoneId: draft.zoneId!,
        goalZoneId: _goalZoneIsRequired(draft.result) ? draft.goalZoneId : null,
        shotType: draft.zoneId == 11 ? 'seven_meter' : 'open_play',
        shotResult: draft.result,
        attackContext: _attackContextApplies(draft.result)
            ? draft.attackContext
            : 'normal',
        period: _currentPeriod,
        minute: _currentMinute,
        second: _currentSecond,
        sequenceOrder: sequence,
        createdBy: user?.id,
        notes: null,
      );

      _optimisticallyApplyShotEvent(event);

      await _shotRepository.createShotEvent(event);

      if (!mounted) return;

      _rightShotDraft.value = const _ShotDraft();
      _scheduleShotRefresh();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar evento: $e';
        _shotEventHistory = previousHistory;
        _scoreHome = previousScoreHome;
        _scoreAway = previousScoreAway;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingRight = false;
        });
      }
    }
  }

  Future<void> _saveLeftMatchEvent() async {
    final previousHistory = List<Map<String, dynamic>>.from(_matchEventHistory);

    if (_leftGenericNeedsPlayer() && _leftMatchEventPlayerId == null) {
      setState(() {
        _errorMessage = 'Selecione o jogador do evento do time da esquerda.';
      });
      return;
    }

    setState(() {
      _isSavingLeftMatchEvent = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      final sequence = _nextGenericSequenceOrderLocal();

      final event = MatchEventModel(
        id: '',
        matchId: widget.match.id,
        competitionId: widget.match.competitionId,
        teamId: widget.match.homeTeamId,
        playerId: _leftGenericNeedsPlayer() ? _leftMatchEventPlayerId : null,
        eventType: _leftMatchEventType,
        period: _currentPeriod,
        minute: _currentMinute,
        second: _currentSecond,
        sequenceOrder: sequence,
        createdBy: user?.id,
        notes: null,
      );

      _optimisticallyApplyGenericEvent(event);

      await _matchEventRepository.createMatchEvent(event);

      if (!mounted) return;

      setState(() {
        _leftMatchEventPlayerId = null;
        _leftMatchEventType = 'suspension_2min';
      });
      _scheduleGenericRefresh();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar evento da partida: $e';
        _matchEventHistory = previousHistory;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingLeftMatchEvent = false;
        });
      }
    }
  }

  Future<void> _saveRightMatchEvent() async {
    final previousHistory = List<Map<String, dynamic>>.from(_matchEventHistory);

    if (_rightGenericNeedsPlayer() && _rightMatchEventPlayerId == null) {
      setState(() {
        _errorMessage = 'Selecione o jogador do evento do time da direita.';
      });
      return;
    }

    setState(() {
      _isSavingRightMatchEvent = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      final sequence = _nextGenericSequenceOrderLocal();

      final event = MatchEventModel(
        id: '',
        matchId: widget.match.id,
        competitionId: widget.match.competitionId,
        teamId: widget.match.awayTeamId,
        playerId: _rightGenericNeedsPlayer() ? _rightMatchEventPlayerId : null,
        eventType: _rightMatchEventType,
        period: _currentPeriod,
        minute: _currentMinute,
        second: _currentSecond,
        sequenceOrder: sequence,
        createdBy: user?.id,
        notes: null,
      );

      _optimisticallyApplyGenericEvent(event);

      await _matchEventRepository.createMatchEvent(event);

      if (!mounted) return;

      setState(() {
        _rightMatchEventPlayerId = null;
        _rightMatchEventType = 'suspension_2min';
      });
      _scheduleGenericRefresh();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar evento da partida: $e';
        _matchEventHistory = previousHistory;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingRightMatchEvent = false;
        });
      }
    }
  }

  Widget _buildResultButtons({
    required String selectedResult,
    required ValueChanged<String> onSelected,
    required bool compact,
  }) {
    Widget resultButton(String value, String label) {
      final isSelected = selectedResult == value;

      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : null,
          minimumSize: compact ? const Size(62, 32) : const Size(74, 36),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 8,
          ),
          textStyle: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () => onSelected(value),
        child: Text(label),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        resultButton('goal', 'Gol'),
        resultButton('out', 'Fora'),
        resultButton('post', 'Trave'),
        resultButton('saved', 'Defesa'),
        resultButton('blocked', 'Bloqueado'),
      ],
    );
  }

  Widget _buildAttackContextButtons({
    required String selectedAttackContext,
    required ValueChanged<String> onSelected,
    required bool compact,
  }) {
    Widget contextButton(String value, String label) {
      final isSelected = selectedAttackContext == value;

      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.purple : null,
          minimumSize: compact ? const Size(92, 32) : const Size(108, 36),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 8,
          ),
          textStyle: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () => onSelected(value),
        child: Text(label),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        contextButton('normal', 'Gol normal'),
        contextButton('contra_ataque', 'Contra-ataque'),
      ],
    );
  }

  Widget _buildPlayerButtons({
    required List<Map<String, dynamic>> players,
    required String? selectedPlayerId,
    required ValueChanged<String> onSelected,
    required bool compact,
  }) {
    final numberedPlayers = players
        .where((player) => player['shirt_number'] is int)
        .toList();

    if (numberedPlayers.isEmpty) {
      return const Text(
        'Nenhum atleta com numero de camisa preenchido para esta equipe.',
      );
    }

    List<String> playerLabels(String fullName) {
      final parts = fullName
          .trim()
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();

      if (parts.isEmpty) return const ['--', '--'];
      if (parts.length == 1) {
        return [parts.first, ''];
      }

      return [parts[0], parts[1]];
    }

    Widget playerButton(Map<String, dynamic> player) {
      final id = player['id'] as String;
      final shirtNumber = player['shirt_number'];
      final name = player['full_name'] as String? ?? 'Jogador';
      final isSelected = selectedPlayerId == id;
      final labels = playerLabels(name);

      return Tooltip(
        message: name,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelected(id),
            child: Container(
              width: compact ? 56 : 66,
              height: compact ? 60 : 70,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFB74D) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFFF57C00) : Colors.grey.shade400,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shirtNumber?.toString() ?? '?',
                    style: TextStyle(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    labels[0],
                    style: TextStyle(
                      fontSize: compact ? 8.5 : 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade700,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    labels[1],
                    style: TextStyle(
                      fontSize: compact ? 8.5 : 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade700,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: numberedPlayers.map(playerButton).toList(),
    );
  }

  Widget _buildGenericEventButtons({
    required String selectedEventType,
    required ValueChanged<String> onSelected,
    required bool compact,
  }) {
    Widget eventButton(String value, String label) {
      final isSelected = selectedEventType == value;

      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.teal : null,
          minimumSize: compact ? const Size(80, 32) : const Size(94, 36),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 8,
          ),
          textStyle: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () => onSelected(value),
        child: Text(label),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        eventButton('suspension_2min', '2 min'),
        eventButton('yellow_card', 'Amarelo'),
        eventButton('red_card', 'Vermelho'),
        eventButton('blue_card', 'Azul'),
        eventButton('timeout', 'Timeout'),
      ],
    );
  }

Widget _buildClockControls() {
  Widget periodButton(String value) {
    final isSelected = _currentPeriod == value;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.indigo : null,
        minimumSize: const Size(110, 42),
      ),
      onPressed: () => _changePeriod(value),
      child: Text(_periodLabel(value)),
    );
  }

  return Column(
    children: [
      Text(
        _formattedClock(),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _periodLabel(_currentPeriod),
        style: const TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          periodButton('first_half'),
          periodButton('second_half'),
          periodButton('extra_time_1'),
          periodButton('extra_time_2'),
          periodButton('penalties'),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _toggleClock,
            child: Text(_isClockRunning ? 'Pause' : 'Play'),
          ),
          ElevatedButton(
            onPressed: _resetClock,
            child: const Text('Reset'),
          ),
        ],
      ),
    ],
  );
}

Widget _buildTeamHeader({
  required String teamName,
  required String? shieldUrl,
  required bool isLeft,
}) {
  return SizedBox(
    width: 220,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: shieldUrl != null && shieldUrl.isNotEmpty
              ? Image.network(
                  shieldUrl,
                  width: 76,
                  height: 76,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.shield_outlined,
                      size: 60,
                    );
                  },
                )
              : const Icon(
                  Icons.shield_outlined,
                  size: 60,
                ),
        ),
        const SizedBox(height: 10),
        Text(
          teamName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _buildMatchHeader({
  required String homeName,
  required String awayName,
  required String? homeShieldUrl,
  required String? awayShieldUrl,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildTeamHeader(
              teamName: homeName,
              shieldUrl: homeShieldUrl,
              isLeft: true,
            ),
          ),
        ),
        const SizedBox(width: 28),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_scoreHome',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'x',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '$_scoreAway',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildTeamHeader(
              teamName: awayName,
              shieldUrl: awayShieldUrl,
              isLeft: false,
            ),
          ),
        ),
      ],
    ),
  );
}


  String _shotResultLabel(String value) {
    switch (value) {
      case 'goal':
        return 'Gol';
      case 'out':
        return 'Fora';
      case 'post':
        return 'Trave';
      case 'saved':
        return 'Defesa';
      case 'blocked':
        return 'Bloqueado';
      default:
        return value;
    }
  }

  String _genericEventLabel(String value) {
    switch (value) {
      case 'suspension_2min':
        return '2 min';
      case 'yellow_card':
        return 'Amarelo';
      case 'red_card':
        return 'Vermelho';
      case 'blue_card':
        return 'Azul';
      case 'timeout':
        return 'Timeout';
      default:
        return value;
    }
  }


  Widget _buildShotHistoryList() {
    if (_shotEventHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhum evento de chute lançado ainda.'),
        ),
      );
    }

    String formatTime(Map<String, dynamic> e) {
      final minute = (e['minute'] as int?) ?? 0;
      final second = (e['second'] as int?) ?? 0;
      final period = e['period'] as String? ?? '';
      final mm = minute.toString().padLeft(2, '0');
      final ss = second.toString().padLeft(2, '0');
      return '${_periodLabel(period)} - $mm:$ss';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Eventos de chute',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shotEventHistory.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final event = _shotEventHistory[index];
                final eventId = event['id'] as String;
                final teamId = event['team_id'] as String?;
                final playerId = event['player_id'] as String?;
                final attackContext = event['attack_context'] as String? ?? 'normal';

                final teamName = teamId != null ? (_teamNames[teamId] ?? teamId) : '-';
                final playerName = playerId != null ? (_playerNames[playerId] ?? playerId) : '-';

                final zoneId = event['zone_id'];
                final goalZoneId = event['goal_zone_id'];
                final result = _shotResultLabel(event['shot_result'] as String? ?? '-');
                final goalType = attackContext == 'contra_ataque'
                    ? ' | Contra-ataque'
                    : (event['shot_result'] == 'goal' ? ' | Gol normal' : '');
                final zoneText = zoneId == null
                    ? 'Z--'
                    : 'Z${zoneId.toString().padLeft(2, '0')}';
                final goalZoneText = goalZoneId != null
                    ? ' | G${goalZoneId.toString().padLeft(2, '0')}'
                    : '';

                return ListTile(
                  dense: true,
                  title: Text(
                    '$teamName | $playerName | $result | $zoneText$goalZoneText$goalType',
                  ),
                  subtitle: Text(formatTime(event)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _editShotEvent(event),
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar evento',
                      ),
                      IconButton(
                        onPressed: _isDeletingEvent ? null : () => _deleteShotEvent(eventId),
                        icon: const Icon(Icons.undo),
                        tooltip: 'Desfazer evento',
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericHistoryList() {
    if (_matchEventHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhum evento da partida lançado ainda.'),
        ),
      );
    }

    String formatTime(Map<String, dynamic> e) {
      final minute = (e['minute'] as int?) ?? 0;
      final second = (e['second'] as int?) ?? 0;
      final period = e['period'] as String? ?? '';
      final mm = minute.toString().padLeft(2, '0');
      final ss = second.toString().padLeft(2, '0');
      return '${_periodLabel(period)} - $mm:$ss';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Eventos gerais da partida',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matchEventHistory.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final event = _matchEventHistory[index];
                final eventId = event['id'] as String;
                final teamId = event['team_id'] as String?;
                final playerId = event['player_id'] as String?;

                final teamName = teamId != null ? (_teamNames[teamId] ?? teamId) : '-';
                final playerName = playerId != null ? (_playerNames[playerId] ?? playerId) : 'Sem jogador';
                final eventLabel = _genericEventLabel(event['event_type'] as String? ?? '-');

                return ListTile(
                  dense: true,
                  title: Text('$teamName | $playerName | $eventLabel'),
                  subtitle: Text(formatTime(event)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _editGenericEvent(event),
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar evento',
                      ),
                      IconButton(
                        onPressed: _isDeletingEvent ? null : () => _deleteGenericEvent(eventId),
                        icon: const Icon(Icons.undo),
                        tooltip: 'Desfazer evento',
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplinaryPanel({
    required String title,
    required List<Map<String, dynamic>> players,
    required String? selectedPlayerId,
    required ValueChanged<String> onPlayerChanged,
    required String selectedEventType,
    required ValueChanged<String> onEventTypeChanged,
    required VoidCallback onSave,
    required bool isSaving,
    required bool needsPlayer,
    required bool compact,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Eventos disciplinares - $title',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            if (needsPlayer) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Jogador',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              _buildPlayerButtons(
                players: players,
                selectedPlayerId: selectedPlayerId,
                onSelected: onPlayerChanged,
                compact: compact,
              ),
              const SizedBox(height: 12),
            ],
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Evento',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildGenericEventButtons(
              selectedEventType: selectedEventType,
              onSelected: onEventTypeChanged,
              compact: compact,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(compact ? 36 : 42),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 8 : 10,
                  ),
                  textStyle: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Salvar evento disciplinar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorCard({
    required String title,
    required Widget child,
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: compact ? 13 : 14,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          child,
        ],
      ),
    );
  }

  Widget _buildTeamPanel({
    required String title,
    required List<Map<String, dynamic>> players,
    required String? selectedPlayerId,
    required ValueChanged<String> onPlayerChanged,
    required int? selectedZoneId,
    required ValueChanged<int> onZoneSelected,
    required int? selectedGoalZoneId,
    required ValueChanged<int> onGoalZoneSelected,
    required String selectedResult,
    required ValueChanged<String> onResultChanged,
    required String selectedAttackContext,
    required ValueChanged<String> onAttackContextChanged,
    required VoidCallback onSave,
    required bool isSaving,
    required String? selectedGenericPlayerId,
    required ValueChanged<String> onGenericPlayerChanged,
    required String selectedGenericEventType,
    required ValueChanged<String> onGenericEventTypeChanged,
    required VoidCallback onSaveGenericEvent,
    required bool isSavingGenericEvent,
    required bool genericNeedsPlayer,
  }) {
    final goalZoneEnabled = _goalZoneIsRequired(selectedResult);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final boardGap = compact ? 8.0 : 12.0;

        return Card(
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: compact ? 10 : 12),
                LayoutBuilder(
                  builder: (context, boardConstraints) {
                    final goalBoard = _buildSelectorCard(
                      title: 'Zona no gol',
                      compact: compact,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Opacity(
                            opacity: goalZoneEnabled ? 1 : 0.42,
                            child: RepaintBoundary(
                              child: GoalZoneSelector(
                                selectedGoalZoneId: selectedGoalZoneId,
                                onSelected: onGoalZoneSelected,
                                enabled: goalZoneEnabled,
                              ),
                            ),
                          ),
                          if (!goalZoneEnabled) ...[
                            const SizedBox(height: 8),
                            const Text('Nao se aplica para este resultado.'),
                          ],
                        ],
                      ),
                    );

                    final shotBoard = _buildSelectorCard(
                      title: 'Zona do chute',
                      compact: compact,
                      child: RepaintBoundary(
                        child: ShotZoneSelector(
                          selectedZoneId: selectedZoneId,
                          onSelected: onZoneSelected,
                        ),
                      ),
                    );

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: shotBoard),
                        SizedBox(width: boardGap),
                        Expanded(child: goalBoard),
                      ],
                    );
                  },
                ),
                SizedBox(height: compact ? 12 : 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Jogadores',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                _buildPlayerButtons(
                  players: players,
                  selectedPlayerId: selectedPlayerId,
                  onSelected: onPlayerChanged,
                  compact: compact,
                ),
                SizedBox(height: compact ? 12 : 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Resultado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                _buildResultButtons(
                  selectedResult: selectedResult,
                  onSelected: onResultChanged,
                  compact: compact,
                ),
                if (selectedResult == 'goal') ...[
                  SizedBox(height: compact ? 12 : 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tipo do gol',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAttackContextButtons(
                    selectedAttackContext: selectedAttackContext,
                    onSelected: onAttackContextChanged,
                    compact: compact,
                  ),
                ],
                SizedBox(height: compact ? 12 : 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(compact ? 36 : 42),
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 16,
                        vertical: compact ? 8 : 10,
                      ),
                      textStyle: TextStyle(
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: isSaving ? null : onSave,
                    child: isSaving
                        ? const CircularProgressIndicator()
                        : const Text('Salvar evento'),
                  ),
                ),
                SizedBox(height: compact ? 16 : 20),
                _buildDisciplinaryPanel(
                  title: title,
                  players: players,
                  selectedPlayerId: selectedGenericPlayerId,
                  onPlayerChanged: onGenericPlayerChanged,
                  selectedEventType: selectedGenericEventType,
                  onEventTypeChanged: onGenericEventTypeChanged,
                  onSave: onSaveGenericEvent,
                  isSaving: isSavingGenericEvent,
                  needsPlayer: genericNeedsPlayer,
                  compact: compact,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final homeName = _teamNames[widget.match.homeTeamId] ?? 'Time A';
    final awayName = _teamNames[widget.match.awayTeamId] ?? 'Time B';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scout ao vivo'),
      ),
      body: Focus(
        focusNode: _pageFocusNode,
        autofocus: true,
        onKeyEvent: _handleScoutHotkeys,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildMatchHeader(
                homeName: homeName,
                awayName: awayName,
                homeShieldUrl: _teamShields[widget.match.homeTeamId],
                awayShieldUrl: _teamShields[widget.match.awayTeamId],
              ),
              const SizedBox(height: 16),
              _buildClockControls(),
              const SizedBox(height: 12),
             
              LayoutBuilder(
                builder: (context, constraints) {
                  final vertical = constraints.maxWidth < 720;
                  final homeField = DropdownButtonFormField<String>(
                    initialValue: _currentHomeGoalkeeperId,
                    decoration: InputDecoration(
                      labelText: 'Goleiro atual - $homeName',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _homeGoalkeepers
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item['id'] as String,
                            child: Text(item['full_name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _currentHomeGoalkeeperId = value;
                      });
                    },
                  );
                  final awayField = DropdownButtonFormField<String>(
                    initialValue: _currentAwayGoalkeeperId,
                    decoration: InputDecoration(
                      labelText: 'Goleiro atual - $awayName',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _awayGoalkeepers
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item['id'] as String,
                            child: Text(item['full_name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _currentAwayGoalkeeperId = value;
                      });
                    },
                  );

                  if (vertical) {
                    return Column(
                      children: [
                        homeField,
                        const SizedBox(height: 12),
                        awayField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: homeField),
                      const SizedBox(width: 12),
                      Expanded(child: awayField),
                    ],
                  );
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final homePanel = ValueListenableBuilder<_ShotDraft>(
                    valueListenable: _leftShotDraft,
                    builder: (context, draft, _) {
                      return _buildTeamPanel(
                        title: homeName,
                        players: _homePlayers,
                        selectedPlayerId: draft.playerId,
                        onPlayerChanged: (value) {
                          _leftShotDraft.value = draft.copyWith(playerId: value);
                        },
                        selectedZoneId: draft.zoneId,
                        onZoneSelected: (value) {
                          _leftShotDraft.value = draft.zoneId == value
                              ? draft.copyWith(clearZoneId: true)
                              : draft.copyWith(zoneId: value);
                        },
                        selectedGoalZoneId: draft.goalZoneId,
                        onGoalZoneSelected: (value) {
                          _leftShotDraft.value = draft.goalZoneId == value
                              ? draft.copyWith(clearGoalZoneId: true)
                              : draft.copyWith(goalZoneId: value);
                        },
                        selectedResult: draft.result,
                        onResultChanged: (value) {
                          _leftShotDraft.value = draft.copyWith(
                            result: value,
                            attackContext: value == 'goal' ? draft.attackContext : 'normal',
                            clearGoalZoneId: !_goalZoneIsRequired(value),
                          );
                        },
                        selectedAttackContext: draft.attackContext,
                        onAttackContextChanged: (value) {
                          _leftShotDraft.value = draft.copyWith(attackContext: value);
                        },
                        onSave: _saveLeftEvent,
                        isSaving: _isSavingLeft,
                        selectedGenericPlayerId: _leftMatchEventPlayerId,
                        onGenericPlayerChanged: (value) {
                          setState(() {
                            _leftMatchEventPlayerId = value;
                          });
                        },
                        selectedGenericEventType: _leftMatchEventType,
                        onGenericEventTypeChanged: (value) {
                          setState(() {
                            _leftMatchEventType = value;
                            if (!_leftGenericNeedsPlayer()) {
                              _leftMatchEventPlayerId = null;
                            }
                          });
                        },
                        onSaveGenericEvent: _saveLeftMatchEvent,
                        isSavingGenericEvent: _isSavingLeftMatchEvent,
                        genericNeedsPlayer: _leftGenericNeedsPlayer(),
                      );
                    },
                  );

                  final awayPanel = ValueListenableBuilder<_ShotDraft>(
                    valueListenable: _rightShotDraft,
                    builder: (context, draft, _) {
                      return _buildTeamPanel(
                        title: awayName,
                        players: _awayPlayers,
                        selectedPlayerId: draft.playerId,
                        onPlayerChanged: (value) {
                          _rightShotDraft.value = draft.copyWith(playerId: value);
                        },
                        selectedZoneId: draft.zoneId,
                        onZoneSelected: (value) {
                          _rightShotDraft.value = draft.zoneId == value
                              ? draft.copyWith(clearZoneId: true)
                              : draft.copyWith(zoneId: value);
                        },
                        selectedGoalZoneId: draft.goalZoneId,
                        onGoalZoneSelected: (value) {
                          _rightShotDraft.value = draft.goalZoneId == value
                              ? draft.copyWith(clearGoalZoneId: true)
                              : draft.copyWith(goalZoneId: value);
                        },
                        selectedResult: draft.result,
                        onResultChanged: (value) {
                          _rightShotDraft.value = draft.copyWith(
                            result: value,
                            attackContext: value == 'goal' ? draft.attackContext : 'normal',
                            clearGoalZoneId: !_goalZoneIsRequired(value),
                          );
                        },
                        selectedAttackContext: draft.attackContext,
                        onAttackContextChanged: (value) {
                          _rightShotDraft.value = draft.copyWith(attackContext: value);
                        },
                        onSave: _saveRightEvent,
                        isSaving: _isSavingRight,
                        selectedGenericPlayerId: _rightMatchEventPlayerId,
                        onGenericPlayerChanged: (value) {
                          setState(() {
                            _rightMatchEventPlayerId = value;
                          });
                        },
                        selectedGenericEventType: _rightMatchEventType,
                        onGenericEventTypeChanged: (value) {
                          setState(() {
                            _rightMatchEventType = value;
                            if (!_rightGenericNeedsPlayer()) {
                              _rightMatchEventPlayerId = null;
                            }
                          });
                        },
                        onSaveGenericEvent: _saveRightMatchEvent,
                        isSavingGenericEvent: _isSavingRightMatchEvent,
                        genericNeedsPlayer: _rightGenericNeedsPlayer(),
                      );
                    },
                  );

                  final row = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: homePanel),
                      const SizedBox(width: 12),
                      Expanded(child: awayPanel),
                    ],
                  );

                  if (constraints.maxWidth >= 900) {
                    return row;
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 900,
                      child: row,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildShotHistoryList(),
              const SizedBox(height: 16),
              _buildGenericHistoryList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

