import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import '../admin/admin_home_page.dart';
import '../client/client_home_page.dart';
import '../home/profile_type_selection_page.dart';
import '../scout/scout_home_page.dart';
import '../viewer/viewer_home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _profileRepository = ProfileRepository();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (!mounted) return;

    if (user == null) {
      _goTo(const ProfileTypeSelectionPage());
      return;
    }

    try {
      final profile = await _profileRepository.getCurrentProfile();

      if (!mounted) return;

      if (profile == null || !profile.isActive) {
        await supabase.auth.signOut();
        _goTo(const ProfileTypeSelectionPage());
        return;
      }

      switch (profile.role) {
        case 'admin':
          _goTo(const AdminHomePage());
          break;
        case 'scout':
          _goTo(const ScoutHomePage());
          break;
        case 'cliente':
          _goTo(const ClientHomePage());
          break;
        case 'viewer':
        default:
          _goTo(const ViewerHomePage());
          break;
      }
    } catch (_) {
      if (!mounted) return;
      _goTo(const ProfileTypeSelectionPage());
    }
  }

  void _goTo(Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppThemeColors.line),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SplashMark(),
                SizedBox(height: 18),
                Text(
                  'HandBrasil Stats',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppThemeColors.ink,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Carregando sua experiencia...',
                  style: TextStyle(
                    color: AppThemeColors.slate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    child: LinearProgressIndicator(minHeight: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppThemeColors.primary,
            AppThemeColors.info,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(
        Icons.sports_handball_rounded,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}
