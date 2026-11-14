import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';
import '../../providers/auth_providers.dart';
import 'forgot_password.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _hidePassword = true;

  // Decorative floating emojis: emoji, horizontal and vertical alignment.
  static const _floaters = [
    ('🍛', -0.85, -0.8),
    ('🥘', 0.85, -0.55),
    ('🍕', -0.9, 0.1),
    ('🍰', 0.9, 0.35),
    ('🥞', -0.7, 0.85),
    ('🌶️', 0.7, 0.9),
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = ref.read(authServiceProvider);
    try {
      if (_isLogin) {
        await auth.signIn(_email.text.trim(), _password.text);
      } else {
        await auth.signUp(_name.text.trim(), _email.text.trim(), _password.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: Brand.gradient),
        child: Stack(
          children: [
            for (var i = 0; i < _floaters.length; i++)
              Align(
                alignment: Alignment(_floaters[i].$2, _floaters[i].$3),
                child: Opacity(
                  opacity: 0.35,
                  child: Text(_floaters[i].$1,
                      style: const TextStyle(fontSize: 48)),
                )
                    .animate(
                      delay: (i * 250).ms,
                      onPlay: (c) => c.repeat(reverse: true),
                    )
                    .moveY(
                      begin: -12,
                      end: 12,
                      duration: Duration(milliseconds: 2000 + i * 300),
                      curve: Curves.easeInOut,
                    ),
              ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 40,
                              offset: Offset(0, 20)),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                gradient: Brand.gradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.restaurant_rounded,
                                  color: Colors.white, size: 34),
                            ).animate().scaleXY(
                                begin: 0.5,
                                end: 1,
                                duration: 700.ms,
                                curve: Curves.elasticOut),
                            const SizedBox(height: Sp.md),
                            Text('Kovai Bites',
                                style: t.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Brand.primary)),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: AppMotion.normal,
                              child: Text(
                                _isLogin
                                    ? 'Welcome back, foodie!'
                                    : 'Create your account',
                                key: ValueKey(_isLogin),
                                style: t.textTheme.bodyMedium
                                    ?.copyWith(color: t.colorScheme.outline),
                              ),
                            ),
                            const SizedBox(height: Sp.lg),

                            // The name field slides in only for sign-up.
                            AnimatedSize(
                              duration: AppMotion.normal,
                              curve: Curves.easeOutCubic,
                              child: _isLogin
                                  ? const SizedBox(width: double.infinity)
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: Sp.md),
                                      child: TextFormField(
                                        controller: _name,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        decoration: const InputDecoration(
                                          labelText: 'Full name',
                                          prefixIcon:
                                              Icon(Icons.person_outline),
                                        ),
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                                ? 'Required'
                                                : null,
                                      ),
                                    ),
                            ),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Enter a valid email'
                                  : null,
                            ),
                            const SizedBox(height: Sp.md),
                            TextFormField(
                              controller: _password,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_hidePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                  onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'At least 6 characters'
                                  : null,
                            ),
                            if (_isLogin)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => showForgotPasswordDialog(
                                      context, ref,
                                      initialEmail: _email.text.trim()),
                                  child: const Text('Forgot password?'),
                                ),
                              )
                            else
                              const SizedBox(height: Sp.sm),
                            const SizedBox(height: Sp.sm),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: _loading ? null : _submit,
                                child: AnimatedSwitcher(
                                  duration: AppMotion.fast,
                                  child: _loading
                                      ? const SizedBox(
                                          key: ValueKey('busy'),
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white))
                                      : Text(
                                          _isLogin ? 'Login' : 'Sign up',
                                          key: ValueKey(_isLogin),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: Sp.sm),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isLogin = !_isLogin),
                              child: Text(_isLogin
                                  ? 'New here? Create an account'
                                  : 'Already have an account? Login'),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(
                            begin: 0.12,
                            end: 0,
                            duration: 600.ms,
                            curve: Curves.easeOutCubic),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}