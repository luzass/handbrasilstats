import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_backdrop.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = false;
  bool _hasRecoverySession = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPreparingRecovery = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _hasRecoverySession = Supabase.instance.client.auth.currentSession != null;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.passwordRecovery ||
            data.session != null) {
          if (!mounted) return;
          setState(() {
            _hasRecoverySession = true;
          });
        }
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Erro ao validar link de recuperacao: $error';
        });
      },
    );
    _prepareRecoverySession();
  }

  Future<void> _prepareRecoverySession() async {
    final supabase = Supabase.instance.client;
    final code = Uri.base.queryParameters['code'];
    final fragmentParameters = _getFragmentParameters();
    final accessToken = fragmentParameters['access_token'];
    final refreshToken = fragmentParameters['refresh_token'];

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      try {
        await supabase.auth.setSession(
          refreshToken,
          accessToken: accessToken,
        );

        if (!mounted) return;
        setState(() {
          _hasRecoverySession = true;
          _isPreparingRecovery = false;
          _errorMessage = null;
        });
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _hasRecoverySession = false;
          _isPreparingRecovery = false;
          _errorMessage = e.message;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _hasRecoverySession = false;
          _isPreparingRecovery = false;
          _errorMessage =
              'Nao conseguimos validar esse link. Solicite uma nova recuperacao de senha.';
        });
      }
      return;
    }

    if (code != null && code.isNotEmpty) {
      try {
        await supabase.auth.exchangeCodeForSession(code);

        if (!mounted) return;
        setState(() {
          _hasRecoverySession = true;
          _isPreparingRecovery = false;
          _errorMessage = null;
        });
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _hasRecoverySession = false;
          _isPreparingRecovery = false;
          _errorMessage = e.message.contains('Code verifier')
              ? 'Esse link foi gerado no formato antigo. Solicite uma nova recuperacao de senha.'
              : e.message;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _hasRecoverySession = false;
          _isPreparingRecovery = false;
          _errorMessage =
              'Nao conseguimos validar esse link. Solicite uma nova recuperacao de senha.';
        });
      }
      return;
    }

    if (supabase.auth.currentSession != null) {
      if (!mounted) return;
      setState(() {
        _hasRecoverySession = true;
        _isPreparingRecovery = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _hasRecoverySession = false;
      _isPreparingRecovery = false;
    });
  }

  Map<String, String> _getFragmentParameters() {
    var fragment = Uri.base.fragment;
    if (fragment.isEmpty) return const {};

    if (fragment.startsWith('/') && fragment.contains('?')) {
      fragment = fragment.substring(fragment.indexOf('?') + 1);
    }

    try {
      return Uri.splitQueryString(fragment);
    } catch (_) {
      return const {};
    }
  }

  Future<void> _updatePassword() async {
    FocusScope.of(context).unfocus();

    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Preencha a nova senha e a confirmacao.';
        _successMessage = null;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'A senha deve ter pelo menos 6 caracteres.';
        _successMessage = null;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'As senhas nao coincidem.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;
      setState(() {
        _successMessage = 'Senha atualizada. Agora voce ja pode entrar.';
        _hasRecoverySession = false;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao atualizar senha: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: AppBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppThemeColors.primary,
                              AppThemeColors.info,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.password,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Definir nova senha',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPreparingRecovery
                            ? 'Validando seu link de recuperacao...'
                            : _hasRecoverySession
                            ? 'Digite sua nova senha para concluir a recuperacao.'
                            : 'Abra esta tela pelo link de recuperacao enviado para seu e-mail.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_isPreparingRecovery) ...[
                        const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: _hasRecoverySession && !_isPreparingRecovery,
                        decoration: InputDecoration(
                          labelText: 'Nova senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        enabled: _hasRecoverySession && !_isPreparingRecovery,
                        decoration: InputDecoration(
                          labelText: 'Confirmar nova senha',
                          prefixIcon: const Icon(Icons.verified_user_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_errorMessage != null) ...[
                        _FeedbackBox(
                          message: _errorMessage!,
                          isError: true,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_successMessage != null) ...[
                        _FeedbackBox(
                          message: _successMessage!,
                          isError: false,
                        ),
                        const SizedBox(height: 14),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading || !_hasRecoverySession
                                  || _isPreparingRecovery
                              ? null
                              : _updatePassword,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Salvar nova senha'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  );
                                },
                          child: const Text('Voltar para login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  final String message;
  final bool isError;

  const _FeedbackBox({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFCEAEA) : const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError ? const Color(0xFFF3B9B6) : const Color(0xFFB7E2C4),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? AppThemeColors.danger : AppThemeColors.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
