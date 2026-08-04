import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'modules/auth/forgot_password_page.dart';
import 'modules/auth/login_page.dart';
import 'modules/auth/register_page.dart';
import 'modules/auth/reset_password_page.dart';
import 'modules/splash/splash_page.dart';

class App extends StatelessWidget {
  final String initialRoute;

  const App({
    super.key,
    this.initialRoute = '/',
  });

  Route<dynamic> _buildRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;

    Widget page;
    switch (path) {
      case '/login':
        page = const LoginPage();
        break;
      case '/register':
        page = const RegisterPage(profileType: 'visitor');
        break;
      case '/forgot-password':
        page = const ForgotPasswordPage();
        break;
      case '/reset-password':
        page = const ResetPasswordPage();
        break;
      case '/':
      default:
        page = const SplashPage();
        break;
    }

    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HandBrasil Stats',
      theme: AppTheme.light,
      initialRoute: initialRoute,
      onGenerateRoute: _buildRoute,
    );
  }
}
