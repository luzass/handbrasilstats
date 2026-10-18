import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile_model.dart';
import '../../repositories/player_account_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/cpf_utils.dart';
import '../../widgets/app_backdrop.dart';

class PlayerHomePage extends StatefulWidget {
  const PlayerHomePage({super.key});

  @override
  State<PlayerHomePage> createState() => _PlayerHomePageState();
}

class _PlayerHomePageState extends State<PlayerHomePage> {
  final _profileRepository = ProfileRepository();
  final _repository = PlayerAccountRepository();

  bool _isLoading = true;
  String? _errorMessage;
  ProfileModel? _profile;
  List<PlayerCompetitionLink> _links = [];
  List<PlayerCompetitionStats> _stats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _profileRepository.getCurrentProfile(),
        _repository.getCurrentPlayerCompetitions(),
        _repository.getCurrentPlayerStats(),
      ]);

      if (!mounted) return;

      setState(() {
        _profile = results[0] as ProfileModel?;
        _links = results[1] as List<PlayerCompetitionLink>;
        _stats = results[2] as List<PlayerCompetitionStats>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao carregar sua área: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  String _titleCase(String? value) {
    if (value == null || value.isEmpty) return '-';
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _teamLabel({String? shortName, String? name}) {
    final safeShort = shortName?.trim();
    if (safeShort != null && safeShort.isNotEmpty) return safeShort;
    return name?.trim().isNotEmpty == true ? name!.trim() : 'Time';
  }

  String _pct(double? value) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(1)}%';
  }

  Widget _buildPhoto(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 34,
        backgroundColor: AppThemeColors.primarySoft,
        foregroundImage: NetworkImage(photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 34,
      backgroundColor: AppThemeColors.primarySoft,
      child: Icon(
        Icons.sports_handball_outlined,
        color: AppThemeColors.primary,
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppThemeColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppThemeColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppThemeColors.slate,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(PlayerCompetitionStats item) {
    final teamName = _teamLabel(
      shortName: item.teamShortName,
      name: item.teamName,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhoto(item.photoUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.competitionName,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.playerName} • $teamName',
                        style: const TextStyle(
                          color: AppThemeColors.slate,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildMetric('Jogos', item.matchesCount.toString()),
                _buildMetric('Gols', item.goals.toString()),
                _buildMetric('Chutes', item.shots.toString()),
                _buildMetric('Aproveitamento', _pct(item.shotPercentage)),
                _buildMetric('Defesas sofridas', item.savedShots.toString()),
                _buildMetric('Fora', item.outs.toString()),
                _buildMetric('Trave', item.posts.toString()),
                _buildMetric('Bloqueados', item.blocked.toString()),
                _buildMetric('2 min', item.twoMinutes.toString()),
                _buildMetric('Cartões',
                    '${item.yellowCards}/${item.redCards}/${item.blueCards}'),
                if (item.goalkeeperShotsFaced > 0) ...[
                  _buildMetric(
                    'Defesas como goleiro',
                    item.goalkeeperSaves.toString(),
                  ),
                  _buildMetric(
                    '% defesa',
                    _pct(item.savePercentage),
                  ),
                  _buildMetric(
                    'Chutes enfrentados',
                    item.goalkeeperShotsFaced.toString(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionLink(PlayerCompetitionLink item) {
    final teamName = _teamLabel(
      shortName: item.teamShortName,
      name: item.teamName,
    );
    final competition = item.competitionName ?? 'Competição ainda sem partida';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeColors.line),
      ),
      child: Row(
        children: [
          _buildPhoto(item.photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competition,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$teamName • ${_titleCase(item.category)} ${_titleCase(item.gender)}'
                  '${item.year == null ? '' : ' • ${item.year}'}',
                  style: const TextStyle(
                    color: AppThemeColors.slate,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ainda não encontramos seu cadastro de atleta',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sua conta está protegida com ${CpfUtils.maskFromLast4(_profile?.cpfLast4)}. '
              'Para aparecerem competições e estatísticas aqui, o atleta importado/cadastrado precisa estar com o mesmo CPF.',
              style: const TextStyle(
                color: AppThemeColors.slate,
                height: 1.45,
                fontWeight: FontWeight.w600,
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
      appBar: AppBar(
        title: const Text('Minha área'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AppBackdrop(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppThemeColors.primaryDeep,
                                      AppThemeColors.info,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Suas estatísticas de atleta',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.7,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Conta vinculada por CPF protegido. Aqui aparece só o que encontramos para ${_profile?.fullName ?? 'seu cadastro'}.',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_links.isEmpty)
                                _buildEmptyState()
                              else ...[
                                const Text(
                                  'Campeonatos vinculados',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ..._links.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildCompetitionLink(item),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              const Text(
                                'Estatísticas',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_stats.isEmpty)
                                const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(22),
                                    child: Text(
                                      'Nenhuma estatística encontrada ainda para esse CPF.',
                                    ),
                                  ),
                                )
                              else
                                ..._stats.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildStatsCard(item),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
