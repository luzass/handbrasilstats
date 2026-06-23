import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/team_model.dart';
import '../../repositories/team_repository.dart';

class TeamFormPage extends StatefulWidget {
  final TeamModel? team;

  const TeamFormPage({
    super.key,
    this.team,
  });

  @override
  State<TeamFormPage> createState() => _TeamFormPageState();
}

class _TeamFormPageState extends State<TeamFormPage> {
  final _repository = TeamRepository();
  final _supabase = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _foundingYearController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _coachNameController = TextEditingController();

  String _category = 'adulto';
  String _gender = 'masculino';
  bool _isActive = true;

  bool _isLoading = false;
  String? _errorMessage;

  Uint8List? _selectedShieldBytes;
  String? _selectedShieldFileName;
  String? _existingShieldUrl;

  bool get isEditing => widget.team != null;

  @override
  void initState() {
    super.initState();

    final item = widget.team;
    if (item != null) {
      _nameController.text = item.name;
      _shortNameController.text = item.shortName ?? '';
      _foundingYearController.text = item.foundingYear?.toString() ?? '';
      _cityController.text = item.city ?? '';
      _stateController.text = item.state ?? '';
      _countryController.text = item.country ?? '';
      _coachNameController.text = item.coachName ?? '';
      _existingShieldUrl = item.shieldUrl;
      _category = item.category;
      _gender = item.gender;
      _isActive = item.isActive;
    }
  }

  Future<void> _pickShield() async {
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
          _errorMessage = 'Não foi possível ler o arquivo selecionado.';
        });
        return;
      }

      setState(() {
        _selectedShieldBytes = file.bytes;
        _selectedShieldFileName = file.name;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar escudo: $e';
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

  String _buildShieldPublicUrl(String path) {
    final publicUrl = _supabase.storage.from('team-shields').getPublicUrl(path);
    final cacheVersion = DateTime.now().millisecondsSinceEpoch;
    return '$publicUrl?v=$cacheVersion';
  }

  Future<String?> _uploadShieldIfNeeded(String teamId) async {
    if (_selectedShieldBytes == null) {
      return _existingShieldUrl;
    }

    final ext = _getFileExtension(_selectedShieldFileName);
    final path = 'teams/$teamId.$ext';

    await _supabase.storage.from('team-shields').uploadBinary(
          path,
          _selectedShieldBytes!,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _getContentType(ext),
          ),
        );

    return _buildShieldPublicUrl(path);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Preencha o nome do time.';
      });
      return;
    }

    final foundingYear = _foundingYearController.text.trim().isEmpty
        ? null
        : int.tryParse(_foundingYearController.text.trim());

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final baseModel = TeamModel(
        id: widget.team?.id ?? '',
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim().isEmpty
            ? null
            : _shortNameController.text.trim(),
        category: _category,
        gender: _gender,
        foundingYear: foundingYear,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        shieldUrl: _existingShieldUrl,
        coachName: _coachNameController.text.trim().isEmpty
            ? null
            : _coachNameController.text.trim(),
        isActive: _isActive,
      );

      late TeamModel savedTeam;

      if (isEditing) {
        await _repository.updateTeam(baseModel);
        savedTeam = baseModel;
      } else {
        savedTeam = await _repository.createTeam(baseModel);
      }

      final shieldUrl = await _uploadShieldIfNeeded(savedTeam.id);

      if (shieldUrl != savedTeam.shieldUrl) {
        final updatedModel = TeamModel(
          id: savedTeam.id,
          name: savedTeam.name,
          shortName: savedTeam.shortName,
          category: savedTeam.category,
          gender: savedTeam.gender,
          foundingYear: savedTeam.foundingYear,
          city: savedTeam.city,
          state: savedTeam.state,
          country: savedTeam.country,
          shieldUrl: shieldUrl,
          coachName: savedTeam.coachName,
          isActive: savedTeam.isActive,
        );

        await _repository.updateTeam(updatedModel);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar time: $e';
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
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildShieldPreview() {
    Widget child;

    if (_selectedShieldBytes != null) {
      child = Image.memory(
        _selectedShieldBytes!,
        width: 96,
        height: 96,
        fit: BoxFit.contain,
      );
    } else if (_existingShieldUrl != null && _existingShieldUrl!.isNotEmpty) {
      child = Image.network(
        _existingShieldUrl!,
        width: 96,
        height: 96,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 48),
      );
    } else {
      child = const Icon(Icons.shield_outlined, size: 48);
    }

    return Container(
      width: 110,
      height: 110,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _foundingYearController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _coachNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar time' : 'Novo time'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(_nameController, 'Nome'),
            _buildTextField(_shortNameController, 'Nome curto'),
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
            _buildTextField(
              _foundingYearController,
              'Ano de fundação',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(_cityController, 'Cidade'),
            _buildTextField(_stateController, 'Estado'),
            _buildTextField(_countryController, 'País'),
            _buildTextField(_coachNameController, 'Nome do técnico'),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Escudo do time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildShieldPreview(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _pickShield,
                child: const Text('Selecionar escudo'),
              ),
            ),
            if (_selectedShieldFileName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Arquivo selecionado: $_selectedShieldFileName',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isActive,
              title: const Text('Time ativo'),
              onChanged: (value) {
                setState(() {
                  _isActive = value;
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
                    : Text(isEditing ? 'Salvar alterações' : 'Criar time'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
