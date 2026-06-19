import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/competition_model.dart';
import '../../repositories/viewer_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import 'viewer_competition_matches_page.dart';

class ViewerHomePage extends StatefulWidget {
  const ViewerHomePage({super.key});

  @override
  State<ViewerHomePage> createState() => _ViewerHomePageState();
}

class _ViewerHomePageState extends State<ViewerHomePage> {
  final _repository = ViewerRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<CompetitionModel> _competitions = [];

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    try {
      final competitions = await _repository.getFeaturedCompetitions();

      if (!mounted) return;

      setState(() {
        _competitions = competitions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar competicoes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _openCompetition(CompetitionModel competition) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ViewerCompetitionMatchesPage(competition: competition),
      ),
    );
  }

  Widget _buildCompetitionCard(CompetitionModel competition) {
    final location =
        '${competition.hostCity ?? ''}${competition.hostCity != null && competition.hostState != null ? ' - ' : ''}${competition.hostState ?? ''}'
            .trim();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => _openCompetition(competition),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppThemeColors.info,
                      AppThemeColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      competition.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${competition.category} • ${competition.gender} • ${competition.year}',
                      style: const TextStyle(
                        color: AppThemeColors.slate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        location,
                        style: const TextStyle(
                          color: AppThemeColors.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemeColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Ver jogos e estatisticas',
                        style: TextStyle(
                          color: AppThemeColors.primaryDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Competicoes'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AppBackdrop(
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
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(26),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0F172A),
                                    AppThemeColors.info,
                                    AppThemeColors.primaryDeep,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Acompanhe as competicoes liberadas para o viewer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 31,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.9,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Escolha uma competicao para ver os jogos, os placares e o detalhe publico das partidas.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15.5,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_competitions.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(color: AppThemeColors.line),
                                ),
                                child: const Text(
                                  'Nenhuma competicao foi destacada para o viewer ainda.',
                                  style: TextStyle(
                                    color: AppThemeColors.slate,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  for (var i = 0; i < _competitions.length; i++) ...[
                                    _buildCompetitionCard(_competitions[i]),
                                    if (i != _competitions.length - 1)
                                      const SizedBox(height: 16),
                                  ],
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
}
