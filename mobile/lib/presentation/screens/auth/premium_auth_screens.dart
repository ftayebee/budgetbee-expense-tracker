import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/settings/theme_controller.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/app_routes.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

enum StartupDestination { onboarding, login, dashboard }

StartupDestination resolveStartupDestination({
  required bool hasCompletedOnboarding,
  required bool isAuthenticated,
}) {
  if (isAuthenticated) return StartupDestination.dashboard;
  return hasCompletedOnboarding
      ? StartupDestination.login
      : StartupDestination.onboarding;
}

class PremiumSplashScreen extends StatefulWidget {
  const PremiumSplashScreen({super.key});

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_routeFromStartupState);
  }

  Future<void> _routeFromStartupState() async {
    final authenticated = await context.read<AuthProvider>().checkSession();
    if (!mounted) return;
    final settings = context.read<AppSettingsController>();
    // A valid account session proves this is an existing installation. Do not
    // force established users through onboarding after upgrading.
    if (authenticated && !settings.hasCompletedOnboarding) {
      await settings.completeOnboarding();
    }
    if (!mounted) return;
    final destination = resolveStartupDestination(
      hasCompletedOnboarding: settings.hasCompletedOnboarding,
      isAuthenticated: authenticated,
    );
    Navigator.pushReplacementNamed(context, switch (destination) {
      StartupDestination.onboarding => AppRoutes.onboarding,
      StartupDestination.login => AppRoutes.login,
      StartupDestination.dashboard => AppRoutes.dashboard,
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.darkStage,
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BudgetBeeBrand(size: BrandSize.large, centered: true),
            SizedBox(height: 28),
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    ),
  );
}

class PremiumOnboardingScreen extends StatefulWidget {
  const PremiumOnboardingScreen({super.key});

  @override
  State<PremiumOnboardingScreen> createState() =>
      _PremiumOnboardingScreenState();
}

class _PremiumOnboardingScreenState extends State<PremiumOnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      'Track Every Expense',
      'Record income and spending in seconds and always know where your money goes.',
      _OnboardingArt.transactions,
    ),
    (
      'Understand Your Money',
      'Explore monthly reports, category insights, and clear spending patterns.',
      _OnboardingArt.analytics,
    ),
    (
      'Build Better Habits',
      'Set budgets, monitor progress, and make smarter financial decisions.',
      _OnboardingArt.progress,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<AppSettingsController>().completeOnboarding();
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.darkStage,
    body: Stack(
      children: [
        const Positioned(
          top: -160,
          left: -100,
          right: -100,
          child: _OrangeGlow(height: 360),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 12, 0),
                child: Row(
                  children: [
                    const BudgetBeeBrand(
                      size: BrandSize.compact,
                      showSlogan: false,
                    ),
                    const Spacer(),
                    TextButton(onPressed: _finish, child: const Text('Skip')),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 36,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _OnboardingIllustration(kind: item.$3),
                              const SizedBox(height: 30),
                              Text(
                                item.$1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  height: 1.12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.6,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.$2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.darkMuted,
                                  fontSize: 15,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                child: Column(
                  children: [
                    BudgetBeePageIndicator(count: 3, active: _page),
                    const SizedBox(height: 20),
                    PrototypeButton(
                      label: _page == 2 ? 'Get Started' : 'Next',
                      onPressed: _page == 2
                          ? _finish
                          : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PremiumLoginScreen extends StatefulWidget {
  const PremiumLoginScreen({super.key});

  @override
  State<PremiumLoginScreen> createState() => _PremiumLoginScreenState();
}

class _PremiumLoginScreenState extends State<PremiumLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final ok = await auth.login(_email.text.trim(), _password.text);
    if (mounted && ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.darkStage,
    resizeToAvoidBottomInset: true,
    body: Stack(
      children: [
        const Positioned(
          top: -175,
          left: -120,
          right: -120,
          child: _OrangeGlow(height: 400),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                22,
                24,
                22,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BudgetBeeBrand(
                      size: BrandSize.standard,
                      centered: true,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue managing your money.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.darkMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface.withValues(alpha: .96),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.darkBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .14),
                            blurRadius: 42,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) => Form(
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
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                validator: Validators.required,
                                onFieldSubmitted: (_) =>
                                    auth.loading ? null : _signIn(auth),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.forgotPassword,
                                  ),
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              if (auth.error != null) ...[
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    auth.error!,
                                    style: const TextStyle(
                                      color: AppColors.expense,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              PrototypeButton(
                                label: auth.loading ? 'Signing In…' : 'Sign In',
                                onPressed: auth.loading
                                    ? null
                                    : () => _signIn(auth),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: AppColors.darkMuted),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class BudgetBeePageIndicator extends StatelessWidget {
  const BudgetBeePageIndicator({
    super.key,
    required this.count,
    required this.active,
  });
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      count,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: index == active ? 28 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: index == active ? AppColors.deepGradient : null,
          color: index == active ? null : AppColors.darkBorder,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

class _OrangeGlow extends StatelessWidget {
  const _OrangeGlow({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      height: height,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: .25),
            Colors.transparent,
          ],
          stops: const [.0, .72],
        ),
      ),
    ),
  );
}

enum _OnboardingArt { transactions, analytics, progress }

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.kind});
  final _OnboardingArt kind;

  @override
  Widget build(BuildContext context) => Container(
    height: 230,
    constraints: const BoxConstraints(maxWidth: 330),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppColors.darkBorder),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .12),
          blurRadius: 36,
        ),
      ],
    ),
    child: switch (kind) {
      _OnboardingArt.transactions => const _TransactionComposition(),
      _OnboardingArt.analytics => const _AnalyticsComposition(),
      _OnboardingArt.progress => const _ProgressComposition(),
    },
  );
}

class _TransactionComposition extends StatelessWidget {
  const _TransactionComposition();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Row(
        children: [
          _ArtIcon(icon: Icons.account_balance_wallet_rounded),
          SizedBox(width: 12),
          Expanded(child: _ArtLines()),
          Text(
            '+৳2,400',
            style: TextStyle(
              color: AppColors.income,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Container(height: 1, color: AppColors.darkBorder),
      const SizedBox(height: 14),
      const Row(
        children: [
          _ArtIcon(icon: Icons.shopping_bag_rounded),
          SizedBox(width: 12),
          Expanded(child: _ArtLines()),
          Text(
            '-৳860',
            style: TextStyle(
              color: AppColors.expense,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        height: 42,
        decoration: BoxDecoration(
          gradient: AppColors.deepGradient,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Center(
          child: Text(
            'Add transaction',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ],
  );
}

class _AnalyticsComposition extends StatelessWidget {
  const _AnalyticsComposition();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(painter: _DonutPainter()),
        ),
      ),
      const SizedBox(width: 20),
      const Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MetricBar(width: 1),
            SizedBox(height: 16),
            _MetricBar(width: .72),
            SizedBox(height: 16),
            _MetricBar(width: .48),
          ],
        ),
      ),
    ],
  );
}

class _ProgressComposition extends StatelessWidget {
  const _ProgressComposition();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          _ArtIcon(icon: Icons.savings_rounded),
          SizedBox(width: 12),
          Text(
            'Savings goal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Text(
        '78%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: const LinearProgressIndicator(
          value: .78,
          minHeight: 14,
          backgroundColor: AppColors.darkBorder,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Your consistency is building a stronger future.',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.darkMuted,
          fontSize: 12,
          height: 1.35,
        ),
      ),
    ],
  );
}

class _ArtIcon extends StatelessWidget {
  const _ArtIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: AppColors.primaryLight),
  );
}

class _ArtLines extends StatelessWidget {
  const _ArtLines();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 70,
        height: 9,
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      const SizedBox(height: 7),
      Container(
        width: 45,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.darkBorder,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    ],
  );
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.width});
  final double width;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: width,
      child: Container(
        height: 18,
        decoration: BoxDecoration(
          gradient: AppColors.deepGradient,
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .19
      ..strokeCap = StrokeCap.round;
    paint.color = AppColors.darkBorder;
    canvas.drawArc(rect.deflate(size.width * .12), 0, 6.28, false, paint);
    paint.shader = AppColors.deepGradient.createShader(rect);
    canvas.drawArc(rect.deflate(size.width * .12), -1.57, 4.35, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
