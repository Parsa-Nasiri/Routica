import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/routica_theme.dart';

/// Login / Sign-up screen.
///
/// Supports:
///   • Email + password authentication via Supabase
///   • Google sign-in (requires Google Cloud setup)
///   • Continue without login (guest mode — local data only)
class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = AuthService.instance;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final error = _isSignUp
        ? await auth.signUpWithEmail(
            email: email,
            password: password,
            fullName: _nameController.text.trim(),
          )
        : await auth.signInWithEmail(
            email: email,
            password: password,
          );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        setState(() => _errorMessage = error);
      } else if (_isSignUp) {
        // Show confirmation message for sign-up
        _showSnackBar(
          'Account created! Check your email for verification.',
          RouticaTheme.success,
        );
      }
      // If sign-in succeeded, AuthWrapper will navigate automatically
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    final error = await AuthService.instance.signInWithGoogle();

    if (mounted) {
      setState(() => _isGoogleLoading = false);
      if (error != null) {
        setState(() => _errorMessage = error);
      }
    }
  }

  void _continueAsGuest() {
    ref.read(guestModeProvider.notifier).enable();
    // AuthWrapper will react to the state change
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RouticaTheme.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo / Brand ──
                  _buildLogo(),
                  const SizedBox(height: 40),

                  // ── Toggle: Login / Sign Up ──
                  _buildToggle(),
                  const SizedBox(height: 24),

                  // ── Name field (sign-up only) ──
                  if (_isSignUp) ...[
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Full name',
                      icon: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Email ──
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$')
                          .hasMatch(v.trim())) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Password ──
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: RouticaTheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  // ── Forgot password (login only) ──
                  if (!_isSignUp) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: RouticaTheme.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── Error message ──
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: RouticaTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: RouticaTheme.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: RouticaTheme.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: RouticaTheme.dangerLight,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Main action button ──
                  _buildActionButton(),

                  const SizedBox(height: 20),

                  // ── Divider ──
                  _buildDivider(),
                  const SizedBox(height: 20),

                  // ── Google sign-in ──
                  _buildGoogleButton(),

                  const SizedBox(height: 16),

                  // ── Continue without login ──
                  TextButton(
                    onPressed: _continueAsGuest,
                    child: const Text(
                      'Continue without an account',
                      style: TextStyle(
                        color: RouticaTheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── UI Components ──────────────────────────────────────────────

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [RouticaTheme.secondary, RouticaTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: RouticaTheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.track_changes_rounded,
            size: 40,
            color: Colors.white,
          ),
        )
            .animate()
            .fadeIn(duration: RouticaTheme.animMedium)
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.0, 1.0),
              duration: RouticaTheme.animMedium,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 16),
        const Text(
          'Routica',
          style: TextStyle(
            color: RouticaTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: RouticaTheme.animMedium),
        const SizedBox(height: 4),
        Text(
          _isSignUp ? 'Create your account' : 'Welcome back',
          style: const TextStyle(
            color: RouticaTheme.onSurfaceVariant,
            fontSize: 15,
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: RouticaTheme.animMedium),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: RouticaTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption('Login', !_isSignUp, () {
              setState(() {
                _isSignUp = false;
                _errorMessage = null;
              });
            }),
          ),
          Expanded(
            child: _buildToggleOption('Sign Up', _isSignUp, () {
              setState(() {
                _isSignUp = true;
                _errorMessage = null;
              });
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: RouticaTheme.animFast,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? RouticaTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : RouticaTheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: RouticaTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: RouticaTheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: RouticaTheme.onSurfaceVariant, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: RouticaTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
          borderSide: const BorderSide(color: RouticaTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
          borderSide: const BorderSide(color: RouticaTheme.accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [RouticaTheme.secondary, RouticaTheme.primary],
          ),
          borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
          boxShadow: [
            BoxShadow(
              color: RouticaTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _submit,
            borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _isSignUp ? 'Create Account' : 'Login',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: RouticaTheme.borderStrong, height: 1),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: RouticaTheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: RouticaTheme.borderStrong, height: 1),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: RouticaTheme.surface,
        borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
        child: InkWell(
          onTap: _isGoogleLoading ? null : _signInWithGoogle,
          borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
              border: Border.all(color: RouticaTheme.borderStrong),
            ),
            child: Center(
              child: _isGoogleLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: RouticaTheme.accent,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'G',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: RouticaTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RouticaTheme.surface,
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email and we\'ll send you a reset link.',
              style: TextStyle(
                color: RouticaTheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(color: RouticaTheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.mail_outline,
                    color: RouticaTheme.onSurfaceVariant, size: 20),
                filled: true,
                fillColor: RouticaTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final error = await AuthService.instance
                  .resetPassword(emailController.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                _showSnackBar(
                  error ?? 'Reset link sent! Check your email.',
                  error != null ? RouticaTheme.danger : RouticaTheme.success,
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
