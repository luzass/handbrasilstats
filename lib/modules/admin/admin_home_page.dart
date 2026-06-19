import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import 'admin_competitions_page.dart';
import '../scout/scout_match_list_page.dart';
import '../statistics/match_statistics_list_page.dart';
import '../statistics/team_statistics_list_page.dart';
import 'match_list_page.dart';
import 'player_list_page.dart';
import 'team_list_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _AdminAction(
        title: 'Competições',
        subtitle: 'Cadastros e estrutura dos campeonatos',
        icon: Icons.emoji_events_outlined,
        accent: const Color(0xFFE9A23B),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AdminCompetitionsPage(),
            ),
          );
        },
      ),
      _AdminAction(
        title: 'Times',
        subtitle: 'Dados do time, escudo e elenco',
        icon: Icons.shield_outlined,
        accent: AppThemeColors.primary,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TeamListPage(),
            ),
          );
        },
      ),
      _AdminAction(
        title: 'Jogadores',
        subtitle: 'Cadastro, fotos e informações técnicas',
        icon: Icons.person_outline,
        accent: const Color(0xFF3C82F6),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PlayerListPage(),
            ),
          );
        },
      ),
      _AdminAction(
        title: 'Partidas',
        subtitle: 'Agenda, elenco e status do scout',
        icon: Icons.calendar_month_outlined,
        accent: const Color(0xFF8B5CF6),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MatchListPage(),
            ),
          );
        },
      ),
      _AdminAction(
        title: 'Scout',
        subtitle: 'Lançamento em tempo real da partida',
        icon: Icons.radar_outlined,
        accent: const Color(0xFFEF4444),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ScoutMatchListPage(),
            ),
          );
        },
      ),
      _AdminAction(
        title: 'Estatísticas',
        subtitle: 'Visão detalhada de partidas e desempenhos',
        icon: Icons.insights_outlined,
        accent: const Color(0xFF0F4C81),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MatchStatisticsListPage(),
            ),
          );
        },
      ),
      _AdminAction(
        title: 'Estatísticas dos Times',
        subtitle: 'Leitura consolidada por equipe',
        icon: Icons.bar_chart_outlined,
        accent: const Color(0xFF0F766E),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TeamStatisticsListPage(),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AppBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
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
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.dashboard_customize_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Operação central do HandBrasil Stats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gerencie cadastros, partidas, scout e análises em um fluxo mais organizado e com cara de produto profissional.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Módulos',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    var crossAxisCount = 1;

                    if (width >= 1200) {
                      crossAxisCount = 4;
                    } else if (width >= 900) {
                      crossAxisCount = 3;
                    } else if (width >= 600) {
                      crossAxisCount = 2;
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: actions.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.28,
                      ),
                      itemBuilder: (context, index) {
                        final action = actions[index];

                        return InkWell(
                          onTap: action.onTap,
                          borderRadius: BorderRadius.circular(24),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: action.accent.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      action.icon,
                                      color: action.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    action.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    action.subtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _AdminAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
}
