import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import '../statistics/match_statistics_list_page.dart';
import '../statistics/team_statistics_list_page.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Area do Cliente'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AppBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppThemeColors.primaryDeep,
                            AppThemeColors.info,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 760;

                          final left = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Painel de acompanhamento',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Acompanhe desempenho com uma leitura mais premium e objetiva.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 33,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Aqui o foco e abrir estatisticas, revisar times e ler a performance com menos ruido visual e mais valor percebido.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 15.5,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: compact ? double.infinity : 220,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MatchStatisticsListPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppThemeColors.secondary,
                                      ),
                                      child: const Text('Ver estatisticas'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: compact ? double.infinity : 220,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const TeamStatisticsListPage(),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.28,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Ver equipes'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );

                          final right = const _ClientSummary();

                          return compact
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    left,
                                    const SizedBox(height: 18),
                                    right,
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(flex: 6, child: left),
                                    const SizedBox(width: 18),
                                    Expanded(flex: 4, child: right),
                                  ],
                                );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 900;
                        final cards = const [
                          _ClientFeatureCard(
                            icon: Icons.query_stats_rounded,
                            accent: AppThemeColors.primary,
                            title: 'Leitura consolidada',
                            text:
                                'Acompanhe o rendimento por partida, equipe, atleta e goleiro em uma navegacao mais clara.',
                          ),
                          _ClientFeatureCard(
                            icon: Icons.photo_camera_back_outlined,
                            accent: AppThemeColors.violet,
                            title: 'Identidade visual forte',
                            text:
                                'Escudos, fotos e superficies com mais contraste deixam o produto com cara de app profissional.',
                          ),
                          _ClientFeatureCard(
                            icon: Icons.sports_score_outlined,
                            accent: AppThemeColors.secondary,
                            title: 'Analise orientada ao jogo',
                            text:
                                'As telas foram pensadas para quem precisa enxergar padrao de quadra, e nao planilha crua.',
                          ),
                        ];

                        if (compact) {
                          return Column(
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                cards[i],
                                if (i != cards.length - 1)
                                  const SizedBox(height: 16),
                              ],
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              Expanded(child: cards[i]),
                              if (i != cards.length - 1)
                                const SizedBox(width: 16),
                            ],
                          ],
                        );
                      },
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

class _ClientSummary extends StatelessWidget {
  const _ClientSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ClientBadge(
            label: 'Match analytics',
            value: 'Visao detalhada',
            accent: AppThemeColors.secondary,
          ),
          SizedBox(height: 14),
          _ClientBadge(
            label: 'Team performance',
            value: 'Leitura coletiva',
            accent: AppThemeColors.accent,
          ),
          SizedBox(height: 14),
          _ClientBadge(
            label: 'Athlete focus',
            value: 'Detalhe individual',
            accent: AppThemeColors.success,
          ),
        ],
      ),
    );
  }
}

class _ClientBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _ClientBadge({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
}

class _ClientFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String text;

  const _ClientFeatureCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: AppThemeColors.slate,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
