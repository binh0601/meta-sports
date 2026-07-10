import 'package:flutter/material.dart';

import '../logic/auth_state.dart';
import '../widgets/brand_crest.dart';
import '../widgets/pitch_background.dart';
import 'admin_dashboard_screen.dart';
import 'player_home_screen.dart';
import 'register_screen.dart';

/// Dang nhap: email/password Firebase, Google Sign-In, hoac admin/123456
/// (nha cai, khong qua Firebase).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await action();
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    final next = authState.role == UserRole.admin
        ? const AdminDashboardScreen()
        : const PlayerHomeScreen();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  void _submit() =>
      _run(() => authState.loginEmail(_userCtrl.text, _passCtrl.text));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: PitchBackground(
        imageAsset: 'assets/images/stadium_night.jpg',
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: .7, end: 1),
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOutBack,
                    builder: (_, v, child) => Transform.scale(
                        scale: v,
                        child: Opacity(
                            opacity: v.clamp(0, 1), child: child)),
                    child: const BrandCrest(size: 96),
                  ),
                  const SizedBox(height: 12),
                  const Text('MEGA SPORTS',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: Colors.white,
                      )),
                  const Text('ASIAN CUP EDITION',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 4,
                        color: Color(0xFFFBBF24),
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 4),
                  Text('Sàn kèo thể thao — 100% tiền ảo',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _userCtrl,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: TextStyle(color: scheme.error, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Text('ĐĂNG NHẬP'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() => authState.loginGoogle()),
                      icon: const Icon(Icons.g_mobiledata, size: 30),
                      label: const Text('Tiếp tục với Google'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => setState(() {
                      _userCtrl.text = 'admin';
                      _passCtrl.text = '123456';
                      _error = null;
                    }),
                    child: Text('Đăng nhập nhà cái (admin)',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
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
