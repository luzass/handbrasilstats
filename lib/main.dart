import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? supabaseUrl;
  String? supabaseAnonKey;

  try {
    await dotenv.load(fileName: '.env');
    supabaseUrl = dotenv.env['SUPABASE_URL'];
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  } catch (_) {
    // In web deploys we can inject the values through --dart-define.
  }

  supabaseUrl ??= const String.fromEnvironment('SUPABASE_URL');
  supabaseAnonKey ??= const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Supabase nao configurado. Defina SUPABASE_URL e SUPABASE_ANON_KEY no .env local ou no build do deploy.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: App()));
}
