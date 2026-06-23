import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player_csv_import_result.dart';
import '../models/player_csv_import_row.dart';
import '../models/player_model.dart';

class TeamRosterRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Set<String>> getActivePlayerIds(String teamId) async {
    final response = await _supabase
        .from('team_players')
        .select('player_id')
        .eq('team_id', teamId)
        .eq('is_active', true);

    return (response as List)
        .map((item) => item['player_id'] as String)
        .toSet();
  }

  Future<void> addPlayerToTeam({
    required String teamId,
    required String playerId,
  }) async {
    final response = await _supabase
        .from('team_players')
        .select('player_id')
        .eq('team_id', teamId)
        .eq('player_id', playerId);

    final existingRows = response as List;

    if (existingRows.isEmpty) {
      await _supabase.from('team_players').insert({
        'team_id': teamId,
        'player_id': playerId,
        'is_active': true,
      });
      return;
    }

    await _supabase
        .from('team_players')
        .update({'is_active': true})
        .eq('team_id', teamId)
        .eq('player_id', playerId);
  }

  Future<void> removePlayerFromTeam({
    required String teamId,
    required String playerId,
  }) async {
    await _supabase
        .from('team_players')
        .update({'is_active': false})
        .eq('team_id', teamId)
        .eq('player_id', playerId);
  }

  Future<PlayerCsvImportResult> importPlayersFromRows({
    required String teamId,
    required List<PlayerCsvImportRow> rows,
  }) async {
    var createdCount = 0;
    var updatedCount = 0;
    var rosterLinkedCount = 0;
    var rosterReactivatedCount = 0;
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
        late final String playerId;

        if (existingPlayer == null) {
          final createdPlayer = await _supabase
              .from('players')
              .insert({
                'cpf': _normalizeNullable(row.cpf),
                'full_name': row.fullName,
                'birth_date': _normalizeNullable(row.birthDate),
                'height_cm': row.heightCm,
                'birth_city': _normalizeNullable(row.birthCity),
                'dominant_hand': row.dominantHand ?? 'nao_informado',
                'primary_position': row.primaryPosition ?? 'nao_informado',
                'titles_text': _normalizeNullable(row.titlesText),
                'is_active': row.isActive ?? true,
              })
              .select('id')
              .single();

          playerId = createdPlayer['id'] as String;
          createdCount++;
        } else {
          await _supabase
              .from('players')
              .update(_buildUpdatedPlayerData(existingPlayer, row))
              .eq('id', existingPlayer.id);

          playerId = existingPlayer.id;
          updatedCount++;
        }

        final rosterOutcome = await _upsertTeamPlayer(
          teamId: teamId,
          playerId: playerId,
        );

        if (rosterOutcome == _RosterUpsertOutcome.created) {
          rosterLinkedCount++;
        } else if (rosterOutcome == _RosterUpsertOutcome.reactivated) {
          rosterReactivatedCount++;
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
      rosterLinkedCount: rosterLinkedCount,
      rosterReactivatedCount: rosterReactivatedCount,
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

  Future<_RosterUpsertOutcome> _upsertTeamPlayer({
    required String teamId,
    required String playerId,
  }) async {
    final response = await _supabase
        .from('team_players')
        .select('is_active')
        .eq('team_id', teamId)
        .eq('player_id', playerId)
        .limit(1);

    final existingRows = response as List;

    if (existingRows.isEmpty) {
      await _supabase.from('team_players').insert({
        'team_id': teamId,
        'player_id': playerId,
        'is_active': true,
      });

      return _RosterUpsertOutcome.created;
    }

    final isActive = existingRows.first['is_active'] as bool? ?? false;
    if (!isActive) {
      await _supabase
          .from('team_players')
          .update({'is_active': true})
          .eq('team_id', teamId)
          .eq('player_id', playerId);

      return _RosterUpsertOutcome.reactivated;
    }

    return _RosterUpsertOutcome.alreadyActive;
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

enum _RosterUpsertOutcome {
  created,
  reactivated,
  alreadyActive,
}
