import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/auth_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/app_routes.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

class LightRegisterScreen extends StatefulWidget {
  const LightRegisterScreen({super.key});

  @override
  State<LightRegisterScreen> createState() => _LightRegisterScreenState();
}

class _LightRegisterScreenState extends State<LightRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _register(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final ok = await auth.register(
      _name.text.trim(),
      _email.text.trim(),
      _password.text,
      _confirmation.text,
    );
    if (mounted && ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => AuthFormPage(
    title: 'Create Your Account',
    subtitle: 'Start tracking your money with BudgetBee.',
    onBack: () => Navigator.pop(context),
    form: Consumer<AuthProvider>(
      builder: (context, auth, _) => AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrototypeInput(
                controller: _name,
                label: 'Full Name',
                placeholder: 'Your name',
                icon: Icons.person_outline_rounded,
                validator: Validators.required,
              ),
              const SizedBox(height: 14),
              PrototypeInput(
                controller: _email,
                label: 'Email',
                placeholder: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 14),
              _PasswordField(
                controller: _password,
                label: 'Password',
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 14),
              _PasswordField(
                controller: _confirmation,
                label: 'Confirm Password',
                obscure: _obscureConfirmation,
                onToggle: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
                validator: (value) {
                  final required = Validators.required(value);
                  if (required != null) return required;
                  return value == _password.text
                      ? null
                      : 'Passwords do not match';
                },
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    auth.error!,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              PrototypeButton(
                label: auth.loading ? 'Creating Account…' : 'Create Account',
                onPressed: auth.loading ? null : () => _register(auth),
              ),
            ],
          ),
        ),
      ),
    ),
    footer: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(color: AuthTheme.textSecondary),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Sign In'),
        ),
      ],
    ),
  );
}

class LightForgotPasswordScreen extends StatefulWidget {
  const LightForgotPasswordScreen({super.key});

  @override
  State<LightForgotPasswordScreen> createState() =>
      _LightForgotPasswordScreenState();
}

class _LightForgotPasswordScreenState extends State<LightForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final ok = await auth.forgotPassword(_email.text.trim());
    if (mounted && ok) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) => AuthFormPage(
    title: _sent ? 'Check Your Email' : 'Reset Your Password',
    subtitle: _sent
        ? 'If an account exists for that address, a reset link is on its way.'
        : 'Enter your email and we’ll send a secure password reset link.',
    onBack: () => Navigator.pop(context),
    form: Consumer<AuthProvider>(
      builder: (context, auth, _) => _sent
          ? Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.incomeSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.income,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                PrototypeButton(
                  label: 'Back to Login',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            )
          : Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrototypeInput(
                    controller: _email,
                    label: 'Email',
                    placeholder: 'you@example.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        auth.error!,
                        style: const TextStyle(color: AppColors.expense),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  PrototypeButton(
                    label: auth.loading ? 'Sending…' : 'Send Reset Link',
                    onPressed: auth.loading ? null : () => _submit(auth),
                  ),
                ],
              ),
            ),
    ),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator = Validators.required,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    validator: validator,
    autofillHints: const [AutofillHints.newPassword],
    style: const TextStyle(color: AuthTheme.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      hintText: 'Minimum 8 characters',
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        tooltip: obscure ? 'Show password' : 'Hide password',
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}
