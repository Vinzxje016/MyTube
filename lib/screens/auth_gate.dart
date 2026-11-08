import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/music_player_controller.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUserId;
  bool _isPasswordRecovery = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _lastUserId = Supabase.instance.client.auth.currentUser?.id;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      final userId = state.session?.user.id;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _isPasswordRecovery = true);
      } else if (state.event == AuthChangeEvent.signedOut) {
        setState(() => _isPasswordRecovery = false);
      }
      if (userId != _lastUserId) {
        _lastUserId = userId;
        MusicPlayerController().clearUserState();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (_isPasswordRecovery) {
          return _UpdatePasswordScreen(
            onComplete: () => setState(() => _isPasswordRecovery = false),
          );
        }
        final userId = client.auth.currentUser?.id;
        if (userId != null) return MainShell(key: ValueKey(userId));
        return const _AuthScreen();
      },
    );
  }
}

class _AuthScreen extends StatefulWidget {
  const _AuthScreen();

  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _noticeMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noticeMessage = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      if (_isRegistering) {
        final response = await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          emailRedirectTo: 'io.supabase.flutter://login-callback/',
        );
        if (mounted && response.session == null) {
          setState(() {
            _errorMessage =
                'Kiểm tra email để xác nhận tài khoản rồi đăng nhập.';
          });
        }
      } else {
        await auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Không thể kết nối. Hãy kiểm tra mạng và thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Nhập email hợp lệ trước.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noticeMessage = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
      if (mounted) {
        setState(() {
          _noticeMessage = 'Đã gửi liên kết đặt lại mật khẩu qua email.';
        });
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Không thể gửi email. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      size: 52,
                      color: AppTheme.primaryLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRegistering
                          ? 'Tạo tài khoản MyTube'
                          : 'Đăng nhập MyTube',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Nhập email hợp lệ'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: _isRegistering
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Mật khẩu'),
                      validator: (value) => value == null || value.length < 6
                          ? 'Mật khẩu cần ít nhất 6 ký tự'
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                    ],
                    if (_noticeMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _noticeMessage!,
                        style: const TextStyle(color: AppTheme.emerald),
                      ),
                    ],
                    if (!_isRegistering)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _sendPasswordReset,
                          child: const Text('Quên mật khẩu?'),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isRegistering ? 'Đăng ký' : 'Đăng nhập'),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                              _isRegistering = !_isRegistering;
                              _errorMessage = null;
                            }),
                      child: Text(
                        _isRegistering
                            ? 'Đã có tài khoản? Đăng nhập'
                            : 'Chưa có tài khoản? Đăng ký',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdatePasswordScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const _UpdatePasswordScreen({required this.onComplete});

  @override
  State<_UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<_UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    if (password.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu cần ít nhất 6 ký tự.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      widget.onComplete();
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Không thể cập nhật mật khẩu.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Đặt mật khẩu mới',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    child: _isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Cập nhật mật khẩu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
