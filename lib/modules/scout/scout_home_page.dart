import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import 'scout_match_list_page.dart';

class ScoutHomePage extends StatelessWidget {
  const ScoutHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Scout'),
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
                            Color(0xFF0A1D34),
                            AppThemeColors.info,
                            AppThemeColors.primaryDeep,
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
                                  'Operacao ao vivo da partida',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Entre nas partidas com ritmo de quadra e leitura rapida.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'O fluxo de scout agora parte de uma base mais forte visualmente, sem perder velocidade para registrar eventos em tempo real.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 15.5,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: compact ? double.infinity : 260,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ScoutMatchListPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppThemeColors.secondary,
                                  ),
                                  child: const Text('Abrir partidas para scout'),
                                ),
                              ),
                            ],
                          );

                          final right = Container(
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
                                _ScoutMetric(
                                  title: 'Captura',
                                  value: 'Em tempo real',
                                  accent: AppThemeColors.secondary,
                                ),
                                SizedBox(height: 14),
                                _ScoutMetric(
                                  title: 'Leitura',
                                  value: 'Por zona e atleta',
                                  accent: AppThemeColors.accent,
                                ),
                                SizedBox(height: 14),
                                _ScoutMetric(
                                  title: 'Saida',
                                  value: 'Estatistica pronta',
                                  accent: AppThemeColors.success,
                                ),
                              ],
                            ),
                          );

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
                          _ActionPanel(
                            icon: Icons.flash_on_rounded,
                            accent: AppThemeColors.secondary,
                            title: 'Inicio rapido',
                            text:
                                'Entre direto na lista de partidas para comecar a coleta sem perder tempo.',
                          ),
                          _ActionPanel(
                            icon: Icons.map_outlined,
                            accent: AppThemeColors.info,
                            title: 'Leitura de zonas',
                            text:
                                'Organize o jogo por origem do chute e zona no gol com leitura visual mais clara.',
                          ),
                          _ActionPanel(
                            icon: Icons.groups_2_outlined,
                            accent: AppThemeColors.primary,
                            title: 'Elencos amarrados',
                            text:
                                'O scout conversa melhor com elenco, fotos e jogadores ativos por partida.',
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

class _ScoutMetric extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _ScoutMetric({
    required this.title,
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
                  title,
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

class _ActionPanel extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String text;

  const _ActionPanel({
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
