import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player_csv_import_result.dart';
import '../models/player_csv_import_row.dart';
import '../models/player_model.dart';

class PlayerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PlayerModel>> getPlayers() async {
    final response = await _supabase
        .from('players')
        .select()
        .order('full_name', ascending: true);

    return (response as List)
        .map((item) => PlayerModel.fromMap(item))
        .toList();
  }

  Future<PlayerModel> createPlayer(PlayerModel player) async {
    final response = await _supabase
        .from('players')
        .insert(player.toInsertMap())
        .select()
        .single();

    return PlayerModel.fromMap(response);
  }

  Future<PlayerModel> updatePlayer(PlayerModel player) async {
    final response = await _supabase
        .from('players')
        .update(player.toUpdateMap())
        .eq('id', player.id)
        .select()
        .single();

    return PlayerModel.fromMap(response);
  }

  Future<String> uploadPlayerPhoto({
    required String playerId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final path = '$playerId/photo';

    await _supabase.storage.from('player-photos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return _supabase.storage.from('player-photos').getPublicUrl(path);
  }

  Future<void> removePlayerPhoto({
    required String playerId,
  }) async {
    final path = '$playerId/photo';

    await _supabase.storage.from('player-photos').remove([path]);
  }

  Future<PlayerCsvImportResult> importPlayersFromRows(
    List<PlayerCsvImportRow> rows,
  ) async {
    var createdCount = 0;
    var updatedCount = 0;
    var skippedCount = 0;
    final errors = <String>[];
    final seenKeys = <String>{};

    for (final row in rows) {
      final identityKey = _buildIdentityKey(row);
      if (identityKey == null) {
        skippedCount++;
        errors.add(
          'Linha ${row.sourceRowNumber}: informe ao menos nome ou CPF.',
        );
        continue;
      }

      if (!seenKeys.add(identityKey)) {
        skippedCount++;
        errors.add(
          'Linha ${row.sourceRowNumber}: jogador repetido dentro do CSV.',
        );
        continue;
      }

      try {
        final existingPlayer = await _findExistingPlayer(row);

        if (existingPlayer == null) {
          await _supabase.from('players').insert({
            'cpf': _normalizeNullable(row.cpf),
            'full_name': row.fullName,
            'birth_date': _normalizeNullable(row.birthDate),
            'height_cm': row.heightCm,
            'birth_city': _normalizeNullable(row.birthCity),
            'dominant_hand': row.dominantHand ?? 'nao_informado',
            'primary_position': row.primaryPosition ?? 'nao_informado',
            'titles_text': _normalizeNullable(row.titlesText),
            'is_active': row.isActive ?? true,
          });

          createdCount++;
        } else {
          await _supabase
              .from('players')
              .update(_buildUpdatedPlayerData(existingPlayer, row))
              .eq('id', existingPlayer.id);

          updatedCount++;
        }
      } catch (e) {
        skippedCount++;
        errors.add(
          'Linha ${row.sourceRowNumber}: nao foi possivel importar ${row.fullName} ($e).',
        );
      }
    }

    return PlayerCsvImportResult(
      createdCount: createdCount,
      updatedCount: updatedCount,
      rosterLinkedCount: 0,
      rosterReactivatedCount: 0,
      skippedCount: skippedCount,
      errors: errors,
    );
  }

  Future<PlayerModel?> _findExistingPlayer(PlayerCsvImportRow row) async {
    final cpf = _normalizeNullable(row.cpf);
    if (cpf != null) {
      final cpfResponse = await _supabase
          .from('players')
          .select()
          .eq('cpf', cpf)
          .limit(1)
          .maybeSingle();

      if (cpfResponse != null) {
        return PlayerModel.fromMap(cpfResponse);
      }
    }

    final nameResponse = await _supabase
        .from('players')
        .select()
        .ilike('full_name', row.fullName)
        .limit(1)
        .maybeSingle();

    if (nameResponse == null) {
      return null;
    }

    return PlayerModel.fromMap(nameResponse);
  }

  Map<String, dynamic> _buildUpdatedPlayerData(
    PlayerModel existingPlayer,
    PlayerCsvImportRow row,
  ) {
    return {
      'cpf': _normalizeNullable(row.cpf) ?? existingPlayer.cpf,
      'full_name': row.fullName,
      'birth_date': _normalizeNullable(row.birthDate) ?? existingPlayer.birthDate,
      'height_cm': row.heightCm ?? existingPlayer.heightCm,
      'birth_city': _normalizeNullable(row.birthCity) ?? existingPlayer.birthCity,
      'photo_url': existingPlayer.photoUrl,
      'dominant_hand': row.dominantHand ?? existingPlayer.dominantHand,
      'primary_position': row.primaryPosition ?? existingPlayer.primaryPosition,
      'titles_text': _normalizeNullable(row.titlesText) ?? existingPlayer.titlesText,
      'is_active': row.isActive ?? existingPlayer.isActive,
    };
  }

  String? _buildIdentityKey(PlayerCsvImportRow row) {
    final cpf = _normalizeNullable(row.cpf);
    if (cpf != null) {
      return 'cpf:$cpf';
    }

    final name = row.fullName.trim().toLowerCase();
    if (name.isEmpty) {
      return null;
    }

    return 'name:$name';
  }

  String? _normalizeNullable(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
