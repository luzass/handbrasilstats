import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/competition_model.dart';
import '../../repositories/competition_repository.dart';

class CompetitionFormPage extends StatefulWidget {
  final CompetitionModel? competition;

  const CompetitionFormPage({
    super.key,
    this.competition,
  });

  @override
  State<CompetitionFormPage> createState() => _CompetitionFormPageState();
}

class _CompetitionFormPageState extends State<CompetitionFormPage> {
  final _repository = CompetitionRepository();
  final _supabase = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _yearController = TextEditingController();
  final _organizerController = TextEditingController();
  final _hostCityController = TextEditingController();
  final _hostStateController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _participatingTeamsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _teamCountController = TextEditingController();
  final _advancingTeamCountController = TextEditingController();
  final _standingsController = TextEditingController();
  final _notesController = TextEditingController();

  String _competitionType = 'liga';
  String _category = 'adulto';
  String _gender = 'masculino';
  bool _isPublic = false;
  bool _isFeaturedForViewer = false;

  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageFileName;
  String? _existingImageUrl;

  bool get isEditing => widget.competition != null;

  @override
  void initState() {
    super.initState();

    final item = widget.competition;
    if (item != null) {
      _nameController.text = item.name;
      _shortNameController.text = item.shortName ?? '';
      _yearController.text = item.year.toString();
      _organizerController.text = item.organizer ?? '';
      _hostCityController.text = item.hostCity ?? '';
      _hostStateController.text = item.hostState ?? '';
      _startDateController.text = item.startDate ?? '';
      _endDateController.text = item.endDate ?? '';
      _participatingTeamsController.text = item.participatingTeamsText ?? '';
      _imageUrlController.text = item.imageUrl ?? '';
      _existingImageUrl = item.imageUrl;
      _teamCountController.text = item.teamCount?.toString() ?? '';
      _advancingTeamCountController.text =
          item.advancingTeamCount?.toString() ?? '';
      _standingsController.text = item.standingsText ?? '';
      _notesController.text = item.notes ?? '';
      _competitionType = item.competitionType;
      _category = item.category;
      _gender = item.gender;
      _isPublic = item.isPublic;
      _isFeaturedForViewer = item.isFeaturedForViewer;
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        setState(() {
          _errorMessage = 'Nao foi possivel ler a imagem selecionada.';
        });
        return;
      }

      setState(() {
        _selectedImageBytes = file.bytes;
        _selectedImageFileName = file.name;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar imagem: $e';
      });
    }
  }

  String _getFileExtension(String? fileName) {
    if (fileName == null || !fileName.contains('.')) {
      return 'webp';
    }

    return fileName.split('.').last.toLowerCase();
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'image/webp';
    }
  }

  String _buildImagePublicUrl(String path) {
    final publicUrl =
        _supabase.storage.from('competition-images').getPublicUrl(path);
    final cacheVersion = DateTime.now().millisecondsSinceEpoch;
    return '$publicUrl?v=$cacheVersion';
  }

  Future<String?> _uploadImageIfNeeded(String competitionId) async {
    if (_selectedImageBytes == null) {
      final typedUrl = _imageUrlController.text.trim();
      if (typedUrl.isNotEmpty) return typedUrl;
      return _existingImageUrl;
    }

    final ext = _getFileExtension(_selectedImageFileName);
    final path = 'competitions/$competitionId.$ext';

    await _supabase.storage.from('competition-images').uploadBinary(
          path,
          _selectedImageBytes!,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _getContentType(ext),
          ),
        );

    return _buildImagePublicUrl(path);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty || _yearController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Preencha pelo menos nome e ano.';
      });
      return;
    }

    final year = int.tryParse(_yearController.text.trim());
    if (year == null) {
      setState(() {
        _errorMessage = 'Ano inválido.';
      });
      return;
    }

    final teamCount = _teamCountController.text.trim().isEmpty
        ? null
        : int.tryParse(_teamCountController.text.trim());
    final advancingTeamCount = _advancingTeamCountController.text.trim().isEmpty
        ? null
        : int.tryParse(_advancingTeamCountController.text.trim());

    if (_teamCountController.text.trim().isNotEmpty && teamCount == null) {
      setState(() {
        _errorMessage = 'Quantidade de times invalida.';
      });
      return;
    }

    if (_advancingTeamCountController.text.trim().isNotEmpty &&
        advancingTeamCount == null) {
      setState(() {
        _errorMessage = 'Quantidade de equipes classificadas invalida.';
      });
      return;
    }

    if (advancingTeamCount != null && advancingTeamCount < 0) {
      setState(() {
        _errorMessage = 'A quantidade de equipes classificadas nao pode ser negativa.';
      });
      return;
    }

    if (teamCount != null &&
        advancingTeamCount != null &&
        advancingTeamCount > teamCount) {
      setState(() {
        _errorMessage =
            'A quantidade de equipes classificadas nao pode ser maior que a quantidade de times.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final model = CompetitionModel(
        id: widget.competition?.id ?? '',
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim().isEmpty
            ? null
            : _shortNameController.text.trim(),
        competitionType: _competitionType,
        year: year,
        category: _category,
        gender: _gender,
        organizer: _organizerController.text.trim().isEmpty
            ? null
            : _organizerController.text.trim(),
        hostCity: _hostCityController.text.trim().isEmpty
            ? null
            : _hostCityController.text.trim(),
        hostState: _hostStateController.text.trim().isEmpty
            ? null
            : _hostStateController.text.trim(),
        startDate: _startDateController.text.trim().isEmpty
            ? null
            : _startDateController.text.trim(),
        endDate: _endDateController.text.trim().isEmpty
            ? null
            : _endDateController.text.trim(),
        participatingTeamsText: _participatingTeamsController.text.trim().isEmpty
            ? null
            : _participatingTeamsController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? _existingImageUrl
            : _imageUrlController.text.trim(),
        teamCount: teamCount,
        advancingTeamCount: advancingTeamCount,
        standingsText: _standingsController.text.trim().isEmpty
            ? null
            : _standingsController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isPublic: _isPublic,
        isFeaturedForViewer: _isFeaturedForViewer,
      );

      late CompetitionModel savedCompetition;

      if (isEditing) {
        await _repository.updateCompetition(model);
        savedCompetition = model;
      } else {
        savedCompetition = await _repository.createCompetition(model);
      }

      final imageUrl = await _uploadImageIfNeeded(savedCompetition.id);

      if (imageUrl != savedCompetition.imageUrl) {
        final updatedModel = CompetitionModel(
          id: savedCompetition.id,
          name: savedCompetition.name,
          shortName: savedCompetition.shortName,
          competitionType: savedCompetition.competitionType,
          year: savedCompetition.year,
          category: savedCompetition.category,
          gender: savedCompetition.gender,
          organizer: savedCompetition.organizer,
          hostCity: savedCompetition.hostCity,
          hostState: savedCompetition.hostState,
          startDate: savedCompetition.startDate,
          endDate: savedCompetition.endDate,
          participatingTeamsText: savedCompetition.participatingTeamsText,
          imageUrl: imageUrl,
          teamCount: savedCompetition.teamCount,
          advancingTeamCount: savedCompetition.advancingTeamCount,
          standingsText: savedCompetition.standingsText,
          notes: savedCompetition.notes,
          isPublic: savedCompetition.isPublic,
          isFeaturedForViewer: savedCompetition.isFeaturedForViewer,
        );

        await _repository.updateCompetition(updatedModel);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar competição: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    Widget child;

    if (_selectedImageBytes != null) {
      child = Image.memory(
        _selectedImageBytes!,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
      );
    } else if (_imageUrlController.text.trim().isNotEmpty) {
      child = Image.network(
        _imageUrlController.text.trim(),
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultImagePreview(),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      child = Image.network(
        _existingImageUrl!,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultImagePreview(),
      );
    } else {
      child = _buildDefaultImagePreview();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }

  Widget _buildDefaultImagePreview() {
    return Container(
      color: const Color(0xFFEAF8F6),
      alignment: Alignment.center,
      child: const Icon(
        Icons.emoji_events_outlined,
        size: 54,
        color: Color(0xFF0D7F7A),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _yearController.dispose();
    _organizerController.dispose();
    _hostCityController.dispose();
    _hostStateController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _participatingTeamsController.dispose();
    _imageUrlController.dispose();
    _teamCountController.dispose();
    _advancingTeamCountController.dispose();
    _standingsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar competição' : 'Nova competição'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(_nameController, 'Nome'),
            _buildTextField(_shortNameController, 'Nome curto'),
            _buildTextField(
              _yearController,
              'Ano',
              keyboardType: TextInputType.number,
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Foto da competicao',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildImagePreview(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _pickImage,
                child: const Text('Selecionar foto da competicao'),
              ),
            ),
            if (_selectedImageFileName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Arquivo selecionado: $_selectedImageFileName',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'URL da foto (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _competitionType,
              decoration: const InputDecoration(
                labelText: 'Tipo da competição',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'zonal', child: Text('Zonal')),
                DropdownMenuItem(
                  value: 'classificatoria',
                  child: Text('Classificatoria'),
                ),
                DropdownMenuItem(value: 'fase_final', child: Text('Fase Final')),
                DropdownMenuItem(value: 'liga', child: Text('Liga')),
                DropdownMenuItem(value: 'copa', child: Text('Copa')),
                DropdownMenuItem(value: 'outro', child: Text('Outro')),
              ],
              onChanged: (value) {
                setState(() {
                  _competitionType = value ?? 'liga';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'adulto', child: Text('Adulto')),
                DropdownMenuItem(value: 'junior', child: Text('Júnior')),
                DropdownMenuItem(value: 'juvenil', child: Text('Juvenil')),
                DropdownMenuItem(value: 'cadete', child: Text('Cadete')),
                DropdownMenuItem(value: 'infantil', child: Text('Infantil')),
                DropdownMenuItem(value: 'outro', child: Text('Outro')),
              ],
              onChanged: (value) {
                setState(() {
                  _category = value ?? 'adulto';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'Gênero',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
                DropdownMenuItem(value: 'misto', child: Text('Misto')),
              ],
              onChanged: (value) {
                setState(() {
                  _gender = value ?? 'masculino';
                });
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(_organizerController, 'Organizador'),
            _buildTextField(_hostCityController, 'Cidade sede'),
            _buildTextField(_hostStateController, 'Estado sede'),
            _buildTextField(_startDateController, 'Data início (YYYY-MM-DD)'),
            _buildTextField(_endDateController, 'Data fim (YYYY-MM-DD)'),
            _buildTextField(
              _participatingTeamsController,
              'Times participantes',
              maxLines: 3,
            ),
            _buildTextField(
              _teamCountController,
              'Quantidade de times',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              _advancingTeamCountController,
              'Equipes que se classificam para a proxima fase',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              _standingsController,
              'Classificação',
              maxLines: 3,
            ),
            _buildTextField(
              _notesController,
              'Observações',
              maxLines: 4,
            ),
            SwitchListTile(
              value: _isPublic,
              title: const Text('Competição pública'),
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),
            SwitchListTile(
              value: _isFeaturedForViewer,
              title: const Text('Destacar para viewer'),
              onChanged: (value) {
                setState(() {
                  _isFeaturedForViewer = value;
                });
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(isEditing ? 'Salvar alterações' : 'Criar competição'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
