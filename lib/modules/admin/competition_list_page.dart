import 'package:flutter/material.dart';

import '../../models/competition_model.dart';
import '../../repositories/competition_repository.dart';
import 'competition_form_page.dart';

class CompetitionListPage extends StatefulWidget {
  const CompetitionListPage({super.key});

  @override
  State<CompetitionListPage> createState() => _CompetitionListPageState();
}

class _CompetitionListPageState extends State<CompetitionListPage> {
  final _repository = CompetitionRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<CompetitionModel> _competitions = [];

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.getCompetitions();

      if (!mounted) return;

      setState(() {
        _competitions = items;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar competições: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openForm([CompetitionModel? competition]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompetitionFormPage(competition: competition),
      ),
    );

    await _loadCompetitions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Competições'),
        actions: [
          IconButton(
            onPressed: () => _openForm(),
            tooltip: 'Adicionar competição',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _competitions.isEmpty
                  ? const Center(child: Text('Nenhuma competição cadastrada.'))
                  : ListView.builder(
                      itemCount: _competitions.length,
                      itemBuilder: (context, index) {
                        final item = _competitions[index];

                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.year} | ${item.category} | ${item.competitionType}'
                            '${item.advancingTeamCount != null ? ' | Classificam: ${item.advancingTeamCount}' : ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openForm(item),
                          ),
                        );
                      },
                    ),
    );
  }
}
