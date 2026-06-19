import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/player_model.dart';
import '../../repositories/player_repository.dart';

class PlayerFormPage extends StatefulWidget {
  final PlayerModel? player;

  const PlayerFormPage({
    super.key,
    this.player,
  });

  @override
  State<PlayerFormPage> createState() => _PlayerFormPageState();
}

class _PlayerFormPageState extends State<PlayerFormPage> {
  final _repository = PlayerRepository();

  final _cpfController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _heightController = TextEditingController();
  final _birthCityController = TextEditingController();
  final _titlesController = TextEditingController();

  String _dominantHand = 'nao_informado';
  String _primaryPosition = 'nao_informado';
  bool _isActive = true;

  bool _isLoading = false;
  String? _errorMessage;

  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoFileName;
  String? _existingPhotoUrl;

  bool get isEditing => widget.player != null;

  @override
  void initState() {
    super.initState();

    final item = widget.player;
    if (item != null) {
      _cpfController.text = item.cpf ?? '';
      _fullNameController.text = item.fullName;
      _birthDateController.text = item.birthDate ?? '';
      _heightController.text = item.heightCm?.toString() ?? '';
      _birthCityController.text = item.birthCity ?? '';
      _existingPhotoUrl = item.photoUrl;
      _titlesController.text = item.titlesText ?? '';
      _dominantHand = item.dominantHand;
      _primaryPosition = item.primaryPosition;
      _isActive = item.isActive;
    }
  }

  Future<void> _pickPhoto() async {
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
        _selectedPhotoBytes = file.bytes;
        _selectedPhotoFileName = file.name;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar foto: $e';
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

  Future<String?> _uploadPhotoIfNeeded(String playerId) async {
    if (_selectedPhotoBytes == null) {
      return _existingPhotoUrl;
    }

    final extension = _getFileExtension(_selectedPhotoFileName);

    return _repository.uploadPlayerPhoto(
      playerId: playerId,
      bytes: _selectedPhotoBytes!,
      contentType: _getContentType(extension),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_fullNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Preencha o nome do jogador.';
      });
      return;
    }

    final height = _heightController.text.trim().isEmpty
        ? null
        : double.tryParse(_heightController.text.trim().replaceAll(',', '.'));

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final baseModel = PlayerModel(
        id: widget.player?.id ?? '',
        cpf: _cpfController.text.trim().isEmpty ? null : _cpfController.text.trim(),
        fullName: _fullNameController.text.trim(),
        birthDate: _birthDateController.text.trim().isEmpty
            ? null
            : _birthDateController.text.trim(),
        heightCm: height,
        birthCity: _birthCityController.text.trim().isEmpty
            ? null
            : _birthCityController.text.trim(),
        photoUrl: _existingPhotoUrl,
        dominantHand: _dominantHand,
        primaryPosition: _primaryPosition,
        titlesText: _titlesController.text.trim().isEmpty
            ? null
            : _titlesController.text.trim(),
        isActive: _isActive,
      );

      late PlayerModel savedPlayer;

      if (isEditing) {
        savedPlayer = await _repository.updatePlayer(baseModel);
      } else {
        savedPlayer = await _repository.createPlayer(baseModel);
      }

      final photoUrl = await _uploadPhotoIfNeeded(savedPlayer.id);

      if (photoUrl != savedPlayer.photoUrl) {
        await _repository.updatePlayer(
          PlayerModel(
            id: savedPlayer.id,
            cpf: savedPlayer.cpf,
            fullName: savedPlayer.fullName,
            birthDate: savedPlayer.birthDate,
            heightCm: savedPlayer.heightCm,
            birthCity: savedPlayer.birthCity,
            photoUrl: photoUrl,
            dominantHand: savedPlayer.dominantHand,
            primaryPosition: savedPlayer.primaryPosition,
            titlesText: savedPlayer.titlesText,
            isActive: savedPlayer.isActive,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar jogador: $e';
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

  Widget _buildPhotoPreview() {
    Widget child;

    if (_selectedPhotoBytes != null) {
      child = ClipOval(
        child: Image.memory(
          _selectedPhotoBytes!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      );
    } else if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          _existingPhotoUrl!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.person_outline, size: 48),
        ),
      );
    } else {
      child = const Icon(Icons.person_outline, size: 48);
    }

    return Container(
      width: 110,
      height: 110,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _fullNameController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _birthCityController.dispose();
    _titlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar jogador' : 'Novo jogador'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(_cpfController, 'CPF'),
            _buildTextField(_fullNameController, 'Nome completo'),
            _buildTextField(_birthDateController, 'Data de nascimento (YYYY-MM-DD)'),
            _buildTextField(
              _heightController,
              'Altura em cm',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            _buildTextField(_birthCityController, 'Cidade natal'),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Foto do jogador',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildPhotoPreview(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _pickPhoto,
                child: const Text('Selecionar foto'),
              ),
            ),
            if (_selectedPhotoFileName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Arquivo selecionado: $_selectedPhotoFileName',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _dominantHand,
              decoration: const InputDecoration(
                labelText: 'Mão dominante',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'destro', child: Text('Destro')),
                DropdownMenuItem(value: 'canhoto', child: Text('Canhoto')),
                DropdownMenuItem(value: 'ambidestro', child: Text('Ambidestro')),
                DropdownMenuItem(value: 'nao_informado', child: Text('Não informado')),
              ],
              onChanged: (value) {
                setState(() {
                  _dominantHand = value ?? 'nao_informado';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _primaryPosition,
              decoration: const InputDecoration(
                labelText: 'Posição principal',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'goleiro', child: Text('Goleiro')),
                DropdownMenuItem(value: 'ponta_esquerda', child: Text('Ponta esquerda')),
                DropdownMenuItem(value: 'armador_esquerdo', child: Text('Armador esquerdo')),
                DropdownMenuItem(value: 'armador_central', child: Text('Armador central')),
                DropdownMenuItem(value: 'armador_direito', child: Text('Armador direito')),
                DropdownMenuItem(value: 'ponta_direita', child: Text('Ponta direita')),
                DropdownMenuItem(value: 'pivo', child: Text('Pivô')),
                DropdownMenuItem(value: 'nao_informado', child: Text('Não informado')),
              ],
              onChanged: (value) {
                setState(() {
                  _primaryPosition = value ?? 'nao_informado';
                });
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _titlesController,
              'Títulos',
              maxLines: 3,
            ),
            SwitchListTile(
              value: _isActive,
              title: const Text('Jogador ativo'),
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
                    : Text(isEditing ? 'Salvar alterações' : 'Criar jogador'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
