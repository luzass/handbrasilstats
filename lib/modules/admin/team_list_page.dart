import 'package:flutter/material.dart';

import '../../models/team_model.dart';
import '../../repositories/team_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import 'team_form_page.dart';
import 'team_roster_page.dart';

class TeamListPage extends StatefulWidget {
  const TeamListPage({super.key});

  @override
  State<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends State<TeamListPage> {
  final _repository = TeamRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<TeamModel> _teams = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.getTeams();

      if (!mounted) return;

      setState(() {
        _teams = items;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar times: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openForm([TeamModel? team]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamFormPage(team: team),
      ),
    );

    await _loadTeams();
  }

  Future<void> _openRoster(TeamModel team) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamRosterPage(team: team),
      ),
    );

    await _loadTeams();
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppThemeColors.ink,
        ),
      ),
    );
  }

  Widget _buildShield(String? url) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3F1),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: url == null || url.isEmpty
          ? const Icon(
              Icons.shield_outlined,
              color: AppThemeColors.primary,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                url,
                width: 38,
                height: 38,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shield_outlined,
                  color: AppThemeColors.primary,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Times'),
        actions: [
          IconButton(
            onPressed: () => _openForm(),
            tooltip: 'Adicionar time',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AppBackdrop(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _teams.isEmpty
                    ? const Center(child: Text('Nenhum time cadastrado.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _teams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _teams[index];

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: ListTile(
                                leading: _buildShield(item.shieldUrl),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _infoChip(item.category),
                                      _infoChip(item.gender),
                                      _infoChip(item.city ?? 'Sem cidade'),
                                    ],
                                  ),
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.groups_outlined),
                                      tooltip: 'Gerenciar elenco',
                                      onPressed: () => _openRoster(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Editar time',
                                      onPressed: () => _openForm(item),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
