import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

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
}