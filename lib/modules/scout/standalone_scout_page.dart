import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../repositories/standalone_scout_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/scout_lance_map_selector.dart';

class StandaloneScoutPage extends StatefulWidget {
  const StandaloneScoutPage({super.key});

  @override
  State<StandaloneScoutPage> createState() => _StandaloneScoutPageState();
}

class _StandaloneScoutPageState extends State<StandaloneScoutPage> {
  final _repository = StandaloneScoutRepository();
  final _homeNameController = TextEditingController(text: 'Time A');
  final _awayNameController = TextEditingController(text: 'Time B');
  final _homePlayerController = TextEditingController();
  final _awayPlayerController = TextEditingController();
  final _homeGoalkeeperController = TextEditingController();
  final _awayGoalkeeperController = TextEditingController();
  final _pageFocusNode = FocusNode();

  Timer? _clockTimer;
  bool _isConfigured = false;
  bool _isClockRunning = false;
  int _currentMinute = 0;
  int _currentSecond = 0;
  int _homeScore = 0;
  int _awayScore = 0;
  int _nextSequenceOrder = 1;
  String _period = 'first_half';
  String _mobileTeam = 'home';
  String? _matchId;
  String? _homeStandaloneTeamId;
  String? _awayStandaloneTeamId;
  String? _errorMessage;
  bool _isPreparingMatch = false;

  _ShotDraft _homeDraft = const _ShotDraft();
  _ShotDraft _awayDraft = const _ShotDraft();
  final List<_StandaloneScoutEvent> _events = [];
  final Set<String> _deletedLocalEventKeys = {};
  final Map<String, _MatchScoreSnapshot> _latestScoresByMatch = {};

  @override
  void dispose() {
    _clockTimer?.cancel();
    _homeNameController.dispose();
    _awayNameController.dispose();
    _homePlayerController.dispose();
    _awayPlayerController.dispose();
    _homeGoalkeeperController.dispose();
    _awayGoalkeeperController.dispose();
    _pageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _configureMatch() async {
    final homeName = _homeNameController.text.trim();
    final awayName = _awayNameController.text.trim();

    if (homeName.isEmpty || awayName.isEmpty) {
      setState(() {
        _errorMessage = 'Informe o nome dos dois times.';
      });
      return;
    }

    if (_repository.normalizeTeamName(homeName) ==
        _repository.normalizeTeamName(awayName)) {
      setState(() {
        _errorMessage = 'Use nomes diferentes para os dois times.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isPreparingMatch = true;
    });

    try {
      final homeTeam = await _repository.getOrCreateTeam(homeName);
      final awayTeam = await _repository.getOrCreateTeam(awayName);
      final match = await _repository.createMatch(
        homeTeamId: homeTeam['id'] as String,
        awayTeamId: awayTeam['id'] as String,
        homeTeamName: homeTeam['name'] as String? ?? homeName,
        awayTeamName: awayTeam['name'] as String? ?? awayName,
      );

      if (!mounted) return;

      setState(() {
        _homeNameController.text = homeTeam['name'] as String? ?? homeName;
        _awayNameController.text = awayTeam['name'] as String? ?? awayName;
        _homeStandaloneTeamId = homeTeam['id'] as String;
        _awayStandaloneTeamId = awayTeam['id'] as String;
        _matchId = match['id'] as String;
        _isConfigured = true;
        _isPreparingMatch = false;
      });

      _pageFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao criar partida avulsa no Supabase: $e';
        _isPreparingMatch = false;
      });
    }
  }

  void _toggleClock() {
    if (_isClockRunning) {
      _clockTimer?.cancel();
      setState(() {
        _isClockRunning = false;
      });
      return;
    }

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _currentSecond++;
        if (_currentSecond >= 60) {
          _currentSecond = 0;
          _currentMinute++;
        }
      });
    });

    setState(() {
      _isClockRunning = true;
    });
  }

  void _resetClock() {
    _clockTimer?.cancel();
    setState(() {
      _isClockRunning = false;
      _currentMinute = 0;
      _currentSecond = 0;
    });
  }

  String get _clockLabel {
    final minutes = _currentMinute.toString().padLeft(2, '0');
    final seconds = _currentSecond.toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _homeName => _homeNameController.text.trim();
  String get _awayName => _awayNameController.text.trim();

  String _periodLabel(String period) {
    switch (period) {
      case 'second_half':
        return '2º tempo';
      case 'extra_1':
        return 'Prorrogação 1';
      case 'extra_2':
        return 'Prorrogação 2';
      case 'shootout':
        return 'Tiros';
      case 'first_half':
      default:
        return '1º tempo';
    }
  }

  String _resultLabel(String result) {
    switch (result) {
      case 'goal':
        return 'Gol';
      case 'out':
        return 'Fora';
      case 'post':
        return 'Trave';
      case 'saved':
        return 'Defesa';
      default:
        return result;
    }
  }

  String _teamEventLabel(String eventType) {
    switch (eventType) {
      case 'pass_error':
        return 'Erro de passe';
      case 'technical_error':
        return 'Erro técnico';
      default:
        return eventType;
    }
  }

  int _teamAttackCount(String side) {
    return _events.where((event) {
      return event.side == side && event.countsAsAttack;
    }).length;
  }

  int _teamShotCount(String side) {
    return _events.where((event) {
      return event.side == side && event.isShot;
    }).length;
  }

  int _teamErrorCount(String side) {
    return _events.where((event) {
      return event.side == side && event.isTeamEvent;
    }).length;
  }

  bool _needsGoalTarget(String? result) {
    return result == 'goal' || result == 'saved' || result == 'out';
  }

  bool _insideGoalZonesEnabled(String? result) {
    return result == 'goal' || result == 'saved';
  }

  bool _outsideGoalZonesEnabled(String? result) {
    return result == 'out';
  }

  void _updateDraft(String side, _ShotDraft draft) {
    setState(() {
      if (side == 'home') {
        _homeDraft = draft;
      } else {
        _awayDraft = draft;
      }
      _errorMessage = null;
    });
  }

  void _selectShotZone(String side, int zoneId) {
    final draft = side == 'home' ? _homeDraft : _awayDraft;
    _updateDraft(
      side,
      draft.copyWith(
        zoneId: draft.zoneId == zoneId ? null : zoneId,
        clearZone: draft.zoneId == zoneId,
      ),
    );
  }

  void _selectGoalZone(String side, int goalZoneId) {
    final draft = side == 'home' ? _homeDraft : _awayDraft;
    _updateDraft(
      side,
      draft.copyWith(
        goalZoneId: draft.goalZoneId == goalZoneId ? null : goalZoneId,
        clearGoalZone: draft.goalZoneId == goalZoneId,
      ),
    );
  }

  void _selectResult(String side, String result) {
    final draft = side == 'home' ? _homeDraft : _awayDraft;
    final newResult = draft.result == result ? null : result;

    _updateDraft(
      side,
      draft.copyWith(
        result: newResult,
        setResult: true,
        clearGoalZone: !_needsGoalTarget(newResult) ||
            _outsideGoalZonesEnabled(newResult) !=
                _outsideGoalZonesEnabled(draft.result) ||
            _insideGoalZonesEnabled(newResult) !=
                _insideGoalZonesEnabled(draft.result),
      ),
    );
  }

  void _saveEvent(String side) {
    final matchId = _matchId;
    final teamId = side == 'home' ? _homeStandaloneTeamId : _awayStandaloneTeamId;
    final opponentTeamId =
        side == 'home' ? _awayStandaloneTeamId : _homeStandaloneTeamId;

    if (matchId == null || teamId == null || opponentTeamId == null) {
      setState(() {
        _errorMessage = 'A partida avulsa ainda não foi criada no Supabase.';
      });
      return;
    }

    final draft = side == 'home' ? _homeDraft : _awayDraft;
    final playerController =
        side == 'home' ? _homePlayerController : _awayPlayerController;
    final goalkeeperController =
        side == 'home' ? _homeGoalkeeperController : _awayGoalkeeperController;
    final playerNumber = playerController.text.trim();
    final goalkeeperNumber = goalkeeperController.text.trim();

    if (playerNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Informe o número da camisa do jogador.';
      });
      return;
    }

    if (draft.zoneId == null) {
      setState(() {
        _errorMessage = 'Marque a zona do chute.';
      });
      return;
    }

    if (draft.result == null) {
      setState(() {
        _errorMessage = 'Marque se foi gol, trave, fora ou defesa.';
      });
      return;
    }

    if (_needsGoalTarget(draft.result) && draft.goalZoneId == null) {
      setState(() {
        _errorMessage = draft.result == 'out'
            ? 'Marque onde a bola saiu em relação ao gol.'
            : 'Marque a zona no gol.';
      });
      return;
    }

    if (draft.result == 'saved' && goalkeeperNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Informe o número do goleiro adversário.';
      });
      return;
    }

    final nextHomeScore =
        draft.result == 'goal' && side == 'home' ? _homeScore + 1 : _homeScore;
    final nextAwayScore =
        draft.result == 'goal' && side == 'away' ? _awayScore + 1 : _awayScore;
    final sequenceOrder = _nextSequenceOrder++;
    final localKey = 'shot-$sequenceOrder';
    _latestScoresByMatch[matchId] = _MatchScoreSnapshot(
      homeScore: nextHomeScore,
      awayScore: nextAwayScore,
    );
    final event = _StandaloneScoutEvent(
      localKey: localKey,
      kind: 'shot',
      side: side,
      teamName: side == 'home' ? _homeName : _awayName,
      playerNumber: playerNumber,
      goalkeeperNumber: draft.result == 'saved' ? goalkeeperNumber : null,
      result: draft.result!,
      shotZoneId: draft.zoneId!,
      goalZoneId: draft.goalZoneId,
      period: _period,
      minute: _currentMinute,
      second: _currentSecond,
      sequenceOrder: sequenceOrder,
      homeScoreAfter: nextHomeScore,
      awayScoreAfter: nextAwayScore,
    );

    setState(() {
      _homeScore = nextHomeScore;
      _awayScore = nextAwayScore;

      _events.insert(0, event);

      if (side == 'home') {
        _homeDraft = const _ShotDraft();
      } else {
        _awayDraft = const _ShotDraft();
      }
      playerController.clear();
      goalkeeperController.clear();
      _errorMessage = null;
    });

    unawaited(
      _persistEvent(
        localKey: localKey,
        matchId: matchId,
        teamId: teamId,
        opponentTeamId: opponentTeamId,
        eventKind: 'shot',
        eventType: draft.result!,
        period: event.period,
        minute: event.minute,
        second: event.second,
        sequenceOrder: sequenceOrder,
        homeScoreAfter: nextHomeScore,
        awayScoreAfter: nextAwayScore,
        playerNumber: playerNumber,
        goalkeeperNumber: draft.result == 'saved' ? goalkeeperNumber : null,
        shotZoneId: draft.zoneId,
        goalZoneId: draft.goalZoneId,
      ),
    );
  }

  void _saveTeamEvent(String side, String eventType) {
    final matchId = _matchId;
    final teamId = side == 'home' ? _homeStandaloneTeamId : _awayStandaloneTeamId;
    final opponentTeamId =
        side == 'home' ? _awayStandaloneTeamId : _homeStandaloneTeamId;

    if (matchId == null || teamId == null || opponentTeamId == null) {
      setState(() {
        _errorMessage = 'A partida avulsa ainda não foi criada no Supabase.';
      });
      return;
    }

    final sequenceOrder = _nextSequenceOrder++;
    final localKey = 'team-$sequenceOrder';
    final event = _StandaloneScoutEvent(
      localKey: localKey,
      kind: 'team',
      side: side,
      teamName: side == 'home' ? _homeName : _awayName,
      teamEventType: eventType,
      period: _period,
      minute: _currentMinute,
      second: _currentSecond,
      sequenceOrder: sequenceOrder,
      homeScoreAfter: _homeScore,
      awayScoreAfter: _awayScore,
    );

    setState(() {
      _events.insert(0, event);
      _errorMessage = null;
    });

    unawaited(
      _persistEvent(
        localKey: localKey,
        matchId: matchId,
        teamId: teamId,
        opponentTeamId: opponentTeamId,
        eventKind: 'team',
        eventType: eventType,
        period: event.period,
        minute: event.minute,
        second: event.second,
        sequenceOrder: sequenceOrder,
        homeScoreAfter: event.homeScoreAfter,
        awayScoreAfter: event.awayScoreAfter,
      ),
    );
  }

  Future<void> _persistEvent({
    required String localKey,
    required String matchId,
    required String teamId,
    required String opponentTeamId,
    required String eventKind,
    required String eventType,
    required String period,
    required int minute,
    required int second,
    required int sequenceOrder,
    required int homeScoreAfter,
    required int awayScoreAfter,
    String? playerNumber,
    String? goalkeeperNumber,
    int? shotZoneId,
    int? goalZoneId,
  }) async {
    try {
      final created = await _repository.createEvent(
        matchId: matchId,
        teamId: teamId,
        opponentTeamId: opponentTeamId,
        eventKind: eventKind,
        eventType: eventType,
        period: period,
        minute: minute,
        second: second,
        sequenceOrder: sequenceOrder,
        homeScoreAfter: homeScoreAfter,
        awayScoreAfter: awayScoreAfter,
        playerNumber: playerNumber,
        goalkeeperNumber: goalkeeperNumber,
        shotZoneId: shotZoneId,
        goalZoneId: goalZoneId,
      );

      final createdId = created['id'] as String;

      if (_deletedLocalEventKeys.remove(localKey)) {
        await _repository.deleteEvent(createdId);
        return;
      }

      if (eventType == 'goal') {
        final latestScore = _latestScoresByMatch[matchId] ??
            _MatchScoreSnapshot(
              homeScore: homeScoreAfter,
              awayScore: awayScoreAfter,
            );

        await _repository.updateMatchScore(
          matchId: matchId,
          homeScore: latestScore.homeScore,
          awayScore: latestScore.awayScore,
        );
      }

      if (!mounted) return;

      setState(() {
        final index = _events.indexWhere((event) => event.localKey == localKey);
        if (index >= 0) {
          _events[index] = _events[index].copyWith(
            id: createdId,
            isSynced: true,
            clearSyncError: true,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        final index = _events.indexWhere((event) => event.localKey == localKey);
        if (index >= 0) {
          _events[index] = _events[index].copyWith(
            syncError: 'Erro ao salvar no Supabase: $e',
          );
        }
        _errorMessage = 'Um evento não foi salvo no Supabase. Confira o histórico.';
      });
    }
  }

  void _syncCurrentScore() {
    final matchId = _matchId;
    if (matchId == null) return;

    _latestScoresByMatch[matchId] = _MatchScoreSnapshot(
      homeScore: _homeScore,
      awayScore: _awayScore,
    );

    unawaited(
      _repository.updateMatchScore(
        matchId: matchId,
        homeScore: _homeScore,
        awayScore: _awayScore,
      ),
    );
  }

  void _deletePersistedEvent(_StandaloneScoutEvent event) {
    if (event.id != null) {
      unawaited(_repository.deleteEvent(event.id!));
    } else {
      _deletedLocalEventKeys.add(event.localKey);
    }
  }

  void _recalculateScore() {
    _homeScore = _events
        .where((event) => event.side == 'home' && event.result == 'goal')
        .length;
    _awayScore = _events
        .where((event) => event.side == 'away' && event.result == 'goal')
        .length;

    for (var i = _events.length - 1; i >= 0; i--) {
      var homeScore = 0;
      var awayScore = 0;
      for (var j = _events.length - 1; j >= i; j--) {
        final event = _events[j];
        if (event.side == 'home' && event.result == 'goal') {
          homeScore++;
        }
        if (event.side == 'away' && event.result == 'goal') {
          awayScore++;
        }
      }
      _events[i] = _events[i].copyWith(
        homeScoreAfter: homeScore,
        awayScoreAfter: awayScore,
      );
    }
  }

  void _removeEvent(int index) {
    setState(() {
      final event = _events.removeAt(index);
      _deletePersistedEvent(event);
      _recalculateScore();
    });
    _syncCurrentScore();
  }

  void _clearMatch() {
    _clockTimer?.cancel();
    setState(() {
      _isConfigured = false;
      _isPreparingMatch = false;
      _isClockRunning = false;
      _currentMinute = 0;
      _currentSecond = 0;
      _homeScore = 0;
      _awayScore = 0;
      _nextSequenceOrder = 1;
      _period = 'first_half';
      _matchId = null;
      _homeStandaloneTeamId = null;
      _awayStandaloneTeamId = null;
      _homeDraft = const _ShotDraft();
      _awayDraft = const _ShotDraft();
      _events.clear();
      _deletedLocalEventKeys.clear();
      _homePlayerController.clear();
      _awayPlayerController.clear();
      _homeGoalkeeperController.clear();
      _awayGoalkeeperController.clear();
      _errorMessage = null;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyP) {
      _toggleClock();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scout avulso'),
      ),
      body: Focus(
        focusNode: _pageFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: AppBackdrop(
          child: SafeArea(
            child: _isConfigured ? _buildScoutBody() : _buildSetupBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupBody() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sports_handball,
                    size: 42,
                    color: AppThemeColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Partida avulsa',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crie um scout rápido sem cadastrar competição, times ou elenco.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _homeNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Time A',
                      prefixIcon: Icon(Icons.shield_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _awayNameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _configureMatch(),
                    decoration: const InputDecoration(
                      labelText: 'Nome do Time B',
                      prefixIcon: Icon(Icons.shield_outlined),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isPreparingMatch ? null : _configureMatch,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      _isPreparingMatch ? 'Criando partida...' : 'Começar scout',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoutBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final teamPanelWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 44).clamp(360.0, 900.0) / 2;

        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 12 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(compact: compact),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InlineError(message: _errorMessage!),
                ),
              if (compact) ...[
                _buildMobileTeamSwitch(),
                const SizedBox(height: 10),
                _buildTeamPanel(
                  side: _mobileTeam,
                  width: teamPanelWidth,
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTeamPanel(
                        side: 'home',
                        width: teamPanelWidth,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTeamPanel(
                        side: 'away',
                        width: teamPanelWidth,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              _buildHistory(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool compact}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _TeamScoreLabel(
                    name: _homeName,
                    align: TextAlign.right,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    '$_homeScore x $_awayScore',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppThemeColors.ink,
                        ),
                  ),
                ),
                Expanded(
                  child: _TeamScoreLabel(
                    name: _awayName,
                    align: TextAlign.left,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _clockLabel,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _PeriodChip(
                  label: '1º tempo',
                  selected: _period == 'first_half',
                  onTap: () => setState(() => _period = 'first_half'),
                ),
                _PeriodChip(
                  label: '2º tempo',
                  selected: _period == 'second_half',
                  onTap: () => setState(() => _period = 'second_half'),
                ),
                _PeriodChip(
                  label: 'Prorr. 1',
                  selected: _period == 'extra_1',
                  onTap: () => setState(() => _period = 'extra_1'),
                ),
                _PeriodChip(
                  label: 'Prorr. 2',
                  selected: _period == 'extra_2',
                  onTap: () => setState(() => _period = 'extra_2'),
                ),
                _PeriodChip(
                  label: 'Tiros',
                  selected: _period == 'shootout',
                  onTap: () => setState(() => _period = 'shootout'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _toggleClock,
                  icon: Icon(_isClockRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isClockRunning ? 'Pause (P)' : 'Play (P)'),
                ),
                OutlinedButton.icon(
                  onPressed: _resetClock,
                  icon: const Icon(Icons.timer_off_outlined),
                  label: const Text('Zerar tempo'),
                ),
                OutlinedButton.icon(
                  onPressed: _clearMatch,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Nova partida'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTeamSwitch() {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'home', label: Text(_homeName)),
        ButtonSegment(value: 'away', label: Text(_awayName)),
      ],
      selected: {_mobileTeam},
      onSelectionChanged: (selection) {
        setState(() {
          _mobileTeam = selection.first;
        });
      },
    );
  }

  Widget _buildTeamPanel({
    required String side,
    required double width,
  }) {
    final isHome = side == 'home';
    final teamName = isHome ? _homeName : _awayName;
    final opponentName = isHome ? _awayName : _homeName;
    final draft = isHome ? _homeDraft : _awayDraft;
    final playerController =
        isHome ? _homePlayerController : _awayPlayerController;
    final goalkeeperController =
        isHome ? _homeGoalkeeperController : _awayGoalkeeperController;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              teamName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(label: 'Ataques', value: _teamAttackCount(side)),
                _StatPill(label: 'Arremessos', value: _teamShotCount(side)),
                _StatPill(label: 'Erros', value: _teamErrorCount(side)),
              ],
            ),
            const SizedBox(height: 8),
            ScoutLanceMapSelector(
              selectedZoneId: draft.zoneId,
              selectedGoalZoneId: draft.goalZoneId,
              onZoneSelected: (zoneId) => _selectShotZone(side, zoneId),
              onGoalZoneSelected: (goalZoneId) =>
                  _selectGoalZone(side, goalZoneId),
              goalZonesEnabled: _insideGoalZonesEnabled(draft.result),
              outsideGoalZonesEnabled: _outsideGoalZonesEnabled(draft.result),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: playerController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nº da camisa',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Evento',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _ResultButton(
                  label: 'Gol',
                  selected: draft.result == 'goal',
                  color: const Color(0xFF4CAF50),
                  onTap: () => _selectResult(side, 'goal'),
                ),
                _ResultButton(
                  label: 'Trave',
                  selected: draft.result == 'post',
                  color: AppThemeColors.secondary,
                  onTap: () => _selectResult(side, 'post'),
                ),
                _ResultButton(
                  label: 'Fora',
                  selected: draft.result == 'out',
                  color: AppThemeColors.info,
                  onTap: () => _selectResult(side, 'out'),
                ),
                _ResultButton(
                  label: 'Defesa',
                  selected: draft.result == 'saved',
                  color: AppThemeColors.violet,
                  onTap: () => _selectResult(side, 'saved'),
                ),
              ],
            ),
            if (draft.result == 'saved') ...[
              const SizedBox(height: 12),
              TextField(
                controller: goalkeeperController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Nº goleiro adversário ($opponentName)',
                  prefixIcon: const Icon(Icons.sports_handball),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _DraftSummary(draft: draft, resultLabel: _resultLabel),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _saveEvent(side),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar lance'),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Eventos do time',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _TeamEventButton(
                  label: 'Erro de passe',
                  icon: Icons.compare_arrows,
                  onTap: () => _saveTeamEvent(side, 'pass_error'),
                ),
                _TeamEventButton(
                  label: 'Erro técnico',
                  icon: Icons.warning_amber_outlined,
                  onTap: () => _saveTeamEvent(side, 'technical_error'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Histórico de eventos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text('${_events.length} eventos'),
              ],
            ),
            const SizedBox(height: 8),
            if (_events.isEmpty)
              const Text('Nenhum evento salvo ainda.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _events.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: event.isShot
                          ? AppThemeColors.primary.withValues(alpha: 0.12)
                          : AppThemeColors.secondary.withValues(alpha: 0.16),
                      foregroundColor: event.isShot
                          ? AppThemeColors.primary
                          : AppThemeColors.secondary,
                      child: event.isShot
                          ? Text(event.playerNumber!)
                          : const Icon(Icons.error_outline),
                    ),
                    title: Text(
                      event.isShot
                          ? '${event.teamName} - ${_resultLabel(event.result!)}'
                          : '${event.teamName} - ${_teamEventLabel(event.teamEventType!)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      event.isShot
                          ? '${_periodLabel(event.period)} ${event.clockLabel} | '
                              'Z${event.shotZoneId!.toString().padLeft(2, '0')}'
                              '${event.goalTargetLabel == null ? '' : ' -> ${event.goalTargetLabel}'}'
                              '${event.goalkeeperNumber == null ? '' : ' | Goleiro ${event.goalkeeperNumber}'}'
                              ' | Placar ${event.homeScoreAfter} x ${event.awayScoreAfter}'
                              '${event.syncStatusLabel}'
                          : '${_periodLabel(event.period)} ${event.clockLabel} | '
                              'Ataque encerrado por ${_teamEventLabel(event.teamEventType!).toLowerCase()}'
                              ' | Placar ${event.homeScoreAfter} x ${event.awayScoreAfter}'
                              '${event.syncStatusLabel}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remover lance',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeEvent(index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ShotDraft {
  final int? zoneId;
  final int? goalZoneId;
  final String? result;

  const _ShotDraft({
    this.zoneId,
    this.goalZoneId,
    this.result,
  });

  _ShotDraft copyWith({
    int? zoneId,
    int? goalZoneId,
    String? result,
    bool setResult = false,
    bool clearZone = false,
    bool clearGoalZone = false,
  }) {
    return _ShotDraft(
      zoneId: clearZone ? null : zoneId ?? this.zoneId,
      goalZoneId: clearGoalZone ? null : goalZoneId ?? this.goalZoneId,
      result: setResult ? result : this.result,
    );
  }
}

class _MatchScoreSnapshot {
  final int homeScore;
  final int awayScore;

  const _MatchScoreSnapshot({
    required this.homeScore,
    required this.awayScore,
  });
}

class _StandaloneScoutEvent {
  final String localKey;
  final String? id;
  final String kind;
  final String side;
  final String teamName;
  final String? playerNumber;
  final String? goalkeeperNumber;
  final String? result;
  final String? teamEventType;
  final int? shotZoneId;
  final int? goalZoneId;
  final String period;
  final int minute;
  final int second;
  final int sequenceOrder;
  final int homeScoreAfter;
  final int awayScoreAfter;
  final bool isSynced;
  final String? syncError;

  const _StandaloneScoutEvent({
    required this.localKey,
    this.id,
    required this.kind,
    required this.side,
    required this.teamName,
    this.playerNumber,
    this.goalkeeperNumber,
    this.result,
    this.teamEventType,
    this.shotZoneId,
    this.goalZoneId,
    required this.period,
    required this.minute,
    required this.second,
    required this.sequenceOrder,
    required this.homeScoreAfter,
    required this.awayScoreAfter,
    this.isSynced = false,
    this.syncError,
  });

  _StandaloneScoutEvent copyWith({
    String? id,
    int? homeScoreAfter,
    int? awayScoreAfter,
    bool? isSynced,
    String? syncError,
    bool clearSyncError = false,
  }) {
    return _StandaloneScoutEvent(
      localKey: localKey,
      id: id ?? this.id,
      kind: kind,
      side: side,
      teamName: teamName,
      playerNumber: playerNumber,
      goalkeeperNumber: goalkeeperNumber,
      result: result,
      teamEventType: teamEventType,
      shotZoneId: shotZoneId,
      goalZoneId: goalZoneId,
      period: period,
      minute: minute,
      second: second,
      sequenceOrder: sequenceOrder,
      homeScoreAfter: homeScoreAfter ?? this.homeScoreAfter,
      awayScoreAfter: awayScoreAfter ?? this.awayScoreAfter,
      isSynced: isSynced ?? this.isSynced,
      syncError: clearSyncError ? null : syncError ?? this.syncError,
    );
  }

  String get clockLabel {
    final minutes = minute.toString().padLeft(2, '0');
    final seconds = second.toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get isShot => kind == 'shot';

  bool get isTeamEvent => kind == 'team';

  bool get countsAsAttack => isShot || isTeamEvent;

  String get syncStatusLabel {
    if (syncError != null) return ' | Erro ao sincronizar';
    if (!isSynced) return ' | Salvando...';
    return '';
  }

  String? get goalTargetLabel {
    final zoneId = goalZoneId;
    if (zoneId == null) return null;
    if (zoneId <= 9) {
      return 'G${zoneId.toString().padLeft(2, '0')}';
    }
    return 'F${(zoneId - 10).toString().padLeft(2, '0')}';
  }
}

class _TeamScoreLabel extends StatelessWidget {
  final String name;
  final TextAlign align;

  const _TeamScoreLabel({
    required this.name,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      textAlign: align,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;

  const _StatPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppThemeColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: AppThemeColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ResultButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ResultButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: selected ? color : AppThemeColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Text(label),
      ),
    );
  }
}

class _TeamEventButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TeamEventButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

class _DraftSummary extends StatelessWidget {
  final _ShotDraft draft;
  final String Function(String result) resultLabel;

  const _DraftSummary({
    required this.draft,
    required this.resultLabel,
  });

  @override
  Widget build(BuildContext context) {
    final zone = draft.zoneId == null
        ? 'Zona: -'
        : 'Zona: Z${draft.zoneId.toString().padLeft(2, '0')}';
    final goalZone = draft.goalZoneId == null
        ? 'Alvo: -'
        : draft.goalZoneId! <= 9
            ? 'Alvo: G${draft.goalZoneId.toString().padLeft(2, '0')}'
            : 'Alvo: F${(draft.goalZoneId! - 10).toString().padLeft(2, '0')}';
    final result =
        draft.result == null ? 'Evento: -' : 'Evento: ${resultLabel(draft.result!)}';

    return Text(
      '$zone | $goalZone | $result',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFC62828),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
