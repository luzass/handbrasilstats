import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';

class ProfileTypeSelectionPage extends StatefulWidget {
  const ProfileTypeSelectionPage({super.key});

  @override
  State<ProfileTypeSelectionPage> createState() =>
      _ProfileTypeSelectionPageState();
}

class _ProfileTypeSelectionPageState extends State<ProfileTypeSelectionPage> {
  final _scrollController = ScrollController();
  final _plansKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _whoKey = GlobalKey();
  final _contactKey = GlobalKey();

  Future<void> _scrollToSection(GlobalKey key) async {
    final sectionContext = key.currentContext;
    if (sectionContext == null) return;

    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  void _goToRegister(String profileType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterPage(profileType: profileType),
      ),
    );
  }

  void _openMobileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMobileTile('Planos', () {
                  Navigator.pop(context);
                  _scrollToSection(_plansKey);
                }),
                _buildMobileTile('Sobre', () {
                  Navigator.pop(context);
                  _scrollToSection(_aboutKey);
                }),
                _buildMobileTile('Para quem e', () {
                  Navigator.pop(context);
                  _scrollToSection(_whoKey);
                }),
                _buildMobileTile('Contato', () {
                  Navigator.pop(context);
                  _scrollToSection(_contactKey);
                }),
                _buildMobileTile('Login', () {
                  Navigator.pop(context);
                  _goToLogin();
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _goToRegister('visitor');
                    },
                    child: const Text('Criar conta'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileTile(String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppThemeColors.ink,
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppThemeColors.line),
            boxShadow: [
              BoxShadow(
                color: AppThemeColors.ink.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1220),
              child: compact
                  ? Row(
                      children: [
                        const Expanded(
                          child: _BrandLockup(),
                        ),
                        IconButton(
                          onPressed: _openMobileMenu,
                          icon: const Icon(Icons.menu_rounded),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const _BrandLockup(),
                        const Spacer(),
                        Wrap(
                          spacing: 4,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _HeaderLink(
                              label: 'Planos',
                              onTap: () => _scrollToSection(_plansKey),
                            ),
                            _HeaderLink(
                              label: 'Sobre',
                              onTap: () => _scrollToSection(_aboutKey),
                            ),
                            _HeaderLink(
                              label: 'Para quem e',
                              onTap: () => _scrollToSection(_whoKey),
                            ),
                            _HeaderLink(
                              label: 'Contato',
                              onTap: () => _scrollToSection(_contactKey),
                            ),
                            _HeaderLink(
                              label: 'Login',
                              onTap: _goToLogin,
                            ),
                            const SizedBox(width: 8),
                            _HeaderActionButton(
                              label: 'Criar conta',
                              onTap: () => _goToRegister('visitor'),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool compact) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: const Text(
            'Ecossistema de scout, desempenho e visibilidade',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Um app com energia de esporte e inteligencia para ler o jogo.',
          style: TextStyle(
            fontSize: compact ? 38 : 58,
            height: 1.02,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Organize o scout, compare equipes, valorize atletas e transforme estatisticas em decisoes melhores dentro e fora da quadra.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 16,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: compact ? double.infinity : null,
              child: ElevatedButton(
                onPressed: () => _goToRegister('team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 58),
                ),
                child: const Text('Comecar com plano de time'),
              ),
            ),
            SizedBox(
              width: compact ? double.infinity : null,
              child: OutlinedButton(
                onPressed: () => _scrollToSection(_plansKey),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                  minimumSize: const Size(0, 58),
                ),
                child: const Text('Ver planos'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: const [
            _StatPill(label: 'Partidas', value: '+120'),
            _StatPill(label: 'Scout ao vivo', value: 'Tempo real'),
            _StatPill(label: 'Leitura visual', value: 'Por zonas'),
          ],
        ),
      ],
    );

    final right = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppThemeColors.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.sports_score_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Visao rapida da rodada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _ScorePreviewCard(),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _MiniFeatureBadge(
                icon: Icons.flash_on_rounded,
                label: 'Scout em coleta',
              ),
              _MiniFeatureBadge(
                icon: Icons.radar_rounded,
                label: 'Mapa de zonas',
              ),
              _MiniFeatureBadge(
                icon: Icons.verified_outlined,
                label: 'Leitura por atleta',
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 24 : 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF09162B),
            AppThemeColors.info,
            AppThemeColors.primaryDeep,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppThemeColors.ink.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: 24),
                right,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: left),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: right),
              ],
            ),
    );
  }

  Widget _buildSectionIntro(String title, String text, {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: AppThemeColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15.5,
                color: AppThemeColors.slate,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlans(bool compact) {
    final cards = [
      _PlanCardData(
        title: 'Time',
        price: 'R\$ 29,90/mes',
        accent: AppThemeColors.info,
        surface: AppThemeColors.infoSoft,
        icon: Icons.groups_2_outlined,
        buttonText: 'Criar perfil de time',
        profileType: 'team',
        description:
            'Para equipes que querem scout, leitura de jogo e uma base mais profissional para as decisoes do dia a dia.',
        bullets: const [
          'Scout das partidas do proprio time',
          'Analise de adversarios e leitura de zonas',
          'Acesso a estatisticas de atletas e goleiros',
          'Elenco, partidas e operacao em um unico lugar',
        ],
      ),
      _PlanCardData(
        title: 'Jogador',
        price: 'R\$ 9,90/mes',
        accent: AppThemeColors.violet,
        surface: AppThemeColors.violetSoft,
        icon: Icons.sports_handball_outlined,
        buttonText: 'Criar perfil de jogador',
        profileType: 'player',
        description:
            'Para atletas que querem entender melhor sua producao, destacar pontos fortes e construir mais visibilidade.',
        bullets: const [
          'Leitura da melhor zona de arremesso',
          'Historico de desempenho por partida',
          'Analise do comportamento dos goleiros',
          'Base ideal para evolucao tecnica e highlights',
        ],
      ),
      _PlanCardData(
        title: 'Visitante',
        price: 'Gratis',
        accent: AppThemeColors.success,
        surface: AppThemeColors.successSoft,
        icon: Icons.visibility_outlined,
        buttonText: 'Entrar como visitante',
        profileType: 'visitor',
        description:
            'Para quem quer acompanhar competicoes, explorar estatisticas publicas e conhecer a plataforma.',
        bullets: const [
          'Acesso a dados publicos das competicoes',
          'Leitura inicial de jogadores e equipes',
          'Acompanhamento de scouts publicados',
          'Entrada rapida para conhecer o produto',
        ],
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            _PlanCard(
              data: cards[i],
              onTap: () => _goToRegister(cards[i].profileType),
            ),
            if (i != cards.length - 1) const SizedBox(height: 18),
          ],
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(
              child: _PlanCard(
                data: cards[i],
                onTap: () => _goToRegister(cards[i].profileType),
              ),
            ),
            if (i != cards.length - 1) const SizedBox(width: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildAbout(bool compact) {
    final items = [
      const _FeatureCard(
        icon: Icons.analytics_outlined,
        title: 'Leitura clara da partida',
        text:
            'Transforme a coleta da quadra em informacao visual, objetiva e pronta para apoiar decisoes.',
      ),
      const _FeatureCard(
        icon: Icons.grid_view_rounded,
        title: 'Mapa tecnico por zonas',
        text:
            'Entenda de onde os arremessos saem, onde entram e como os padroes se repetem.',
      ),
      const _FeatureCard(
        icon: Icons.workspace_premium_outlined,
        title: 'Experiencia com mais valor percebido',
        text:
            'Visual premium, fotos, escudos e modulos pensados para parecer produto de verdade.',
      ),
      const _FeatureCard(
        icon: Icons.auto_graph_rounded,
        title: 'Evolucao por atleta e equipe',
        text:
            'Compare momentos, descubra tendencias e acompanhe o que realmente esta mudando no jogo.',
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i != items.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.35,
      ),
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildWhoSection(bool compact) {
    final cards = [
      const _AudienceCard(
        accent: AppThemeColors.info,
        icon: Icons.shield_outlined,
        title: 'Clubes e comissoes',
        text:
            'Estruture elenco, leitura de adversarios, scout ao vivo e acompanhamento de performance.',
      ),
      const _AudienceCard(
        accent: AppThemeColors.violet,
        icon: Icons.sports_handball_rounded,
        title: 'Atletas',
        text:
            'Entenda sua producao, fortalece sua apresentacao e acompanhe evolucao com mais contexto.',
      ),
      const _AudienceCard(
        accent: AppThemeColors.success,
        icon: Icons.visibility_outlined,
        title: 'Publico e parceiros',
        text:
            'Acompanhe dados publicos, competicoes e uma vitrine mais moderna para o handebol.',
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i != cards.length - 1) const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildContact(bool compact) {
    final cards = const [
      _ContactInfoCard(
        icon: Icons.mail_outline_rounded,
        title: 'E-mail',
        text: 'contato@handbrasilstats.com',
      ),
      _ContactInfoCard(
        icon: Icons.phone_outlined,
        title: 'WhatsApp',
        text: '(00) 00000-0000',
      ),
      _ContactInfoCard(
        icon: Icons.handshake_outlined,
        title: 'Parcerias',
        text: 'Apresentacao, apoio a equipes e projetos especiais.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            AppThemeColors.panelAlt,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppThemeColors.line),
      ),
      child: compact
          ? Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  cards[i],
                  if (i != cards.length - 1) const SizedBox(height: 16),
                ],
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1) const SizedBox(width: 16),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBottomCta(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 24 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppThemeColors.primaryDeep,
            AppThemeColors.info,
            Color(0xFF0A2740),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppThemeColors.ink.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Pronto para transformar scout em produto e dado em decisao?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Entre com o perfil ideal para voce e leve o HandBrasil Stats para um patamar mais profissional.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 15.5,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _goToRegister('visitor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppThemeColors.primaryDeep,
                  minimumSize: const Size(220, 58),
                ),
                child: const Text('Criar conta gratis'),
              ),
              OutlinedButton(
                onPressed: _goToLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.34),
                  ),
                  minimumSize: const Size(220, 58),
                ),
                child: const Text('Ja tenho conta'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 900;

    return Scaffold(
      body: AppBackdrop(
        child: Column(
          children: [
            _buildHeader(compact),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1220),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(compact),
                        const SizedBox(height: 34),
                        _buildSectionIntro(
                          'Planos com cara de produto',
                          'Escolha a experiencia que combina com seu momento no ecossistema. O foco aqui e dar valor visual, leitura rapida e organizacao real para o handebol.',
                          key: _plansKey,
                        ),
                        _buildPlans(compact),
                        const SizedBox(height: 34),
                        _buildSectionIntro(
                          'Por que o app parece mais forte agora',
                          'A proposta nao e so listar numeros. O app precisa transmitir confianca, ritmo de esporte e valor de plataforma profissional em cada tela.',
                          key: _aboutKey,
                        ),
                        _buildAbout(compact),
                        const SizedBox(height: 34),
                        _buildSectionIntro(
                          'Para quem isso foi pensado',
                          'Cada perfil entra com um objetivo diferente. A plataforma foi organizada para que cada publico entenda seu ganho de forma imediata.',
                          key: _whoKey,
                        ),
                        _buildWhoSection(compact),
                        const SizedBox(height: 34),
                        _buildSectionIntro(
                          'Fale com a gente',
                          'Se voce quiser apresentar para clube, projeto, atleta ou patrocinador, essa base visual ja foi pensada para parecer um produto mais serio.',
                          key: _contactKey,
                        ),
                        _buildContact(compact),
                        const SizedBox(height: 34),
                        _buildBottomCta(compact),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppThemeColors.primary,
                AppThemeColors.info,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.sports_handball_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HandBrasil Stats',
              style: TextStyle(
                color: AppThemeColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Sport analytics for handball',
              style: TextStyle(
                color: AppThemeColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
      child: Text(label),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value  ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorePreviewCard extends StatelessWidget {
  const _ScorePreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF071425).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'AO VIVO',
                style: TextStyle(
                  color: AppThemeColors.secondary.withValues(alpha: 0.96),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                'Scout em coleta',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: _ScoreTeam(
                  team: 'Litoral Hand',
                  score: '28',
                  alignEnd: false,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'x',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: _ScoreTeam(
                  team: 'HandBrasilia',
                  score: '24',
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(
                child: _MetricBar(
                  label: 'Eficiencia',
                  value: '73%',
                  color: AppThemeColors.secondary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricBar(
                  label: 'Defesas',
                  value: '11',
                  color: AppThemeColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreTeam extends StatelessWidget {
  final String team;
  final String score;
  final bool alignEnd;

  const _ScoreTeam({
    required this.team,
    required this.score,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          team,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          score,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: 0.72,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniFeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniFeatureBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCardData {
  final String title;
  final String price;
  final String description;
  final List<String> bullets;
  final Color accent;
  final Color surface;
  final IconData icon;
  final String profileType;
  final String buttonText;

  const _PlanCardData({
    required this.title,
    required this.price,
    required this.description,
    required this.bullets,
    required this.accent,
    required this.surface,
    required this.icon,
    required this.profileType,
    required this.buttonText,
  });
}

class _PlanCard extends StatelessWidget {
  final _PlanCardData data;
  final VoidCallback onTap;

  const _PlanCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: data.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                data.icon,
                color: data.accent,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.price,
              style: TextStyle(
                fontSize: 27,
                color: data.accent,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              data.description,
              style: const TextStyle(
                color: AppThemeColors.slate,
                fontSize: 15,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 18),
            for (final bullet in data.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: data.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: data.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          color: AppThemeColors.ink,
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: data.accent,
                ),
                child: Text(data.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppThemeColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppThemeColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                color: AppThemeColors.slate,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String text;

  const _AudienceCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppThemeColors.line),
      ),
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
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppThemeColors.slate,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _ContactInfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppThemeColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppThemeColors.secondarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppThemeColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppThemeColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppThemeColors.slate,
                    height: 1.55,
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
