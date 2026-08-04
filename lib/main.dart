import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final initialRoute = _initialRouteFromUri(Uri.base);

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
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  runApp(ProviderScope(child: App(initialRoute: initialRoute)));
}

String _initialRouteFromUri(Uri uri) {
  final hasRecoveryCode = uri.queryParameters.containsKey('code');
  final isResetPath =
      uri.path == '/reset-password' || uri.path == '/reset-password/';
  final isRecoveryFragment = uri.fragment.contains('type=recovery') ||
      uri.fragment.contains('access_token=');

  if (isResetPath || hasRecoveryCode || isRecoveryFragment) {
    final query = uri.hasQuery ? '?${uri.query}' : '';
    final fragment = uri.hasFragment ? '#${uri.fragment}' : '';
    return '/reset-password$query$fragment';
  }

  return uri.path.isEmpty ? '/' : uri.path;
}
