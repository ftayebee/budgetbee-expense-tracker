import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../presentation/providers/app_providers.dart';
import '../../presentation/widgets/app_widgets.dart';
import '../../routes/app_routes.dart';
import '../../features/analytics/presentation/premium_analytics_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final ok = await context.read<AuthProvider>().checkSession();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        ok ? AppRoutes.dashboard : AppRoutes.onboarding,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final logoWidth = (MediaQuery.sizeOf(context).width * .68)
        .clamp(200.0, 300.0)
        .toDouble();
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 450),
              tween: Tween(begin: .92, end: 1),
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(width: logoWidth),
                  const SizedBox(height: 14),
                  Text(
                    'Save Smarter',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 34),
                  CircularProgressIndicator(color: colors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  final slides = const [
    (
      '📊',
      'Track Everything',
      'Monitor your income and expenses effortlessly in one place.',
    ),
    (
      '🎯',
      'Set Smart Budgets',
      'Create budgets per category and get alerts before overspending.',
    ),
    (
      '📈',
      'See Your Progress',
      'Beautiful reports show where your money goes each month.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final slide = slides[step];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 64,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(width: 155),
                        const SizedBox(height: 22),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: context.appPrimarySoft,
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: Center(
                            child: Text(
                              slide.$1,
                              style: TextStyle(fontSize: 60),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          slide.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: context.appText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.$3,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: context.appMuted,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _Dots(active: step, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  PrototypeButton(
                    label: step < 2 ? 'Next →' : 'Get Started',
                    onPressed: () => step < 2
                        ? setState(() => step++)
                        : Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          ),
                  ),
                  if (step < 2)
                    PrototypeButton(
                      label: 'Skip',
                      variant: ButtonVariant.ghost,
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.active, required this.color});
  final int active;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      3,
      (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: i == active ? 20 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: i == active ? color : color.withValues(alpha: .4),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(text: 'demo@example.com');
  final password = TextEditingController(text: 'password');

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        children: [
          const Center(child: AppLogo(width: 170)),
          const SizedBox(height: 28),
          Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to continue tracking',
            style: TextStyle(fontSize: 14, color: context.appMuted),
          ),
          const SizedBox(height: 28),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PrototypeInput(
                    controller: email,
                    label: 'Email',
                    placeholder: 'you@email.com',
                    icon: Icons.mail_outline,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 14),
                  PrototypeInput(
                    controller: password,
                    label: 'Password',
                    placeholder: '••••••••',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: Validators.required,
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: Text('Forgot Password?'),
                  ),
                  if (auth.error != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        auth.error!,
                        style: TextStyle(color: AppColors.expense),
                      ),
                    ),
                  const SizedBox(height: 10),
                  PrototypeButton(
                    label: auth.loading ? 'Signing In...' : 'Sign In',
                    onPressed: auth.loading
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            final ok = await auth.login(
                              email.text,
                              password.text,
                            );
                            if (mounted && ok)
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.dashboard,
                              );
                          },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(fontSize: 13, color: context.appMuted),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _DividerLabel('or continue with'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PrototypeButton(
                  label: 'Google',
                  variant: ButtonVariant.outline,
                  onPressed: () {},
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrototypeButton(
                  label: 'Apple',
                  variant: ButtonVariant.outline,
                  onPressed: () {},
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Divider(color: context.appBorder)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: context.appFaint),
        ),
      ),
      Expanded(child: Divider(color: context.appBorder)),
    ],
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      pass = TextEditingController(),
      confirm = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Create Account',
      onBack: () => Navigator.pop(context),
    ),
    body: Consumer<AuthProvider>(
      builder: (context, auth, _) => Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const BudgetBeeBrand(size: BrandSize.standard, centered: true),
            const SizedBox(height: 24),
            Text(
              'Create Your Account',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Fill in your details to get started',
              style: TextStyle(fontSize: 14, color: context.appMuted),
            ),
            const SizedBox(height: 16),
            PrototypeInput(
              controller: name,
              label: 'Full Name',
              placeholder: 'John Doe',
              icon: Icons.person_outline,
              validator: Validators.required,
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: email,
              label: 'Email',
              placeholder: 'you@email.com',
              icon: Icons.mail_outline,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: pass,
              label: 'Password',
              placeholder: 'Min. 8 characters',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: Validators.required,
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: confirm,
              label: 'Confirm Password',
              placeholder: 'Re-enter password',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: Validators.required,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.appPrimarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'By registering, you agree to our Terms of Service and Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (auth.error != null)
              Text(auth.error!, style: TextStyle(color: AppColors.expense)),
            PrototypeButton(
              label: auth.loading ? 'Creating...' : 'Create Account',
              onPressed: auth.loading
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      final ok = await auth.register(
                        name.text,
                        email.text,
                        pass.text,
                        confirm.text,
                      );
                      if (mounted && ok)
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.dashboard,
                        );
                    },
            ),
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Already have an account? Sign In',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  bool sent = false;
  bool submitting = false;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final address = email.text.trim();
    if (address.isEmpty || !address.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    setState(() => submitting = true);
    final ok = await context.read<AuthProvider>().forgotPassword(address);
    if (!mounted) return;
    setState(() => submitting = false);
    if (ok) {
      setState(() => sent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().error ??
                'Could not send the reset link. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Forgot Password',
      onBack: () => Navigator.pop(context),
    ),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: sent
          ? Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.appIncomeSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 42,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Email Sent!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'Check your inbox for the password reset link. It expires in 30 minutes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: context.appMuted,
                  ),
                ),
                const SizedBox(height: 20),
                PrototypeButton(
                  label: 'Back to Login',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset your password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your email and we'll send a reset link to your inbox.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: context.appMuted,
                  ),
                ),
                const SizedBox(height: 24),
                PrototypeInput(
                  controller: email,
                  label: 'Email',
                  placeholder: 'you@email.com',
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 24),
                PrototypeButton(
                  label: submitting ? 'Sending…' : 'Send Reset Link',
                  onPressed: submitting ? null : _submit,
                ),
              ],
            ),
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    await Future.wait([
      context.read<DashboardProvider>().load(),
      context.read<TransactionProvider>().load(),
      context.read<AccountProvider>().load(),
      context.read<CategoryProvider>().load(),
      context.read<BudgetProvider>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const PrototypeBottomNav(active: AppRoutes.dashboard),
    body: Consumer2<DashboardProvider, AuthProvider>(
      builder: (context, state, auth, _) {
        final d = state.dashboard;
        if (state.loading && d == null) return const LoadingWidget();
        if (state.error != null && d == null) return ErrorState(state.error!);
        if (d == null)
          return const PrototypeEmptyState(
            icon: '📊',
            title: 'No dashboard data',
            subtitle: 'Pull to refresh once the API is running.',
          );
        final savings = d.monthlyIncome <= 0
            ? 0.0
            : ((d.monthlyIncome - d.monthlyExpense) / d.monthlyIncome).clamp(
                0.0,
                1.0,
              );
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _DashboardHeader(
                userName: auth.user?.name ?? 'Alex Johnson',
                balance: d.currentBalance,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FloatingSummary(
                          label: 'Income',
                          value: d.totalIncome,
                          color: AppColors.income,
                          soft: context.appIncomeSoft,
                          icon: Icons.arrow_upward,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FloatingSummary(
                          label: 'Expenses',
                          value: d.totalExpense,
                          color: AppColors.expense,
                          soft: context.appExpenseSoft,
                          icon: Icons.arrow_downward,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    _MonthlyOverview(
                      income: d.monthlyIncome,
                      expense: d.monthlyExpense,
                    ),
                    const SizedBox(height: 14),
                    _SavingsCard(
                      rate: savings,
                      saved: d.monthlyIncome - d.monthlyExpense,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: PrototypeButton(
                            label: '+ Add Income',
                            variant: ButtonVariant.income,
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.addTransaction,
                              arguments: 'income',
                            ),
                            height: 46,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrototypeButton(
                            label: '- Add Expense',
                            variant: ButtonVariant.expense,
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.addTransaction,
                              arguments: 'expense',
                            ),
                            height: 46,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SectionHeader(
                      'Recent Transactions',
                      action: TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.transactions,
                        ),
                        child: Text('See all'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (d.recentTransactions.isEmpty)
                      const PrototypeEmptyState(
                        icon: '🧾',
                        title: 'No transactions yet',
                        subtitle: 'Add income or expense to see it here.',
                      )
                    else
                      ...d.recentTransactions
                          .take(5)
                          .map(
                            (tx) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PrototypeTransactionCard(
                                transaction: tx,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.transactionDetails,
                                  arguments: tx,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.userName, required this.balance});
  final String userName;
  final double balance;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 52),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning 👋',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _HeaderIcon(icon: Icons.notifications_none, onTap: () {}),
                  const SizedBox(width: 10),
                  _HeaderIcon(
                    icon: Icons.settings_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.settings),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(balance),
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormatter.display(DateTime.now()),
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _FloatingSummary extends StatelessWidget {
  const _FloatingSummary({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
    required this.icon,
  });
  final String label;
  final double value;
  final Color color;
  final Color soft;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: context.appCard,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 24,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.appMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.format(value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _MonthlyOverview extends StatelessWidget {
  const _MonthlyOverview({required this.income, required this.expense});
  final double income;
  final double expense;
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Jan', income * .70, expense * 1.20),
      ('Feb', income * .61, expense * .95),
      ('Mar', income * .82, expense * 1.10),
      ('Apr', income, expense),
    ];
    final maxVal = math.max(
      1.0,
      rows.map((e) => math.max(e.$2, e.$3)).reduce(math.max),
    );
    return PrototypeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Monthly Overview',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Spacer(),
              PrototypeTag(
                label: 'This Year',
                color: AppColors.primary,
                background: context.appPrimarySoft,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: rows.map((d) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Bar(
                              height: (d.$2 / maxVal) * 72,
                              color: AppColors.income,
                            ),
                            const SizedBox(width: 3),
                            _Bar(
                              height: (d.$3 / maxVal) * 72,
                              color: AppColors.expense,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.$1,
                        style: TextStyle(fontSize: 10, color: context.appFaint),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _Legend(color: AppColors.income, label: 'Income'),
              SizedBox(width: 14),
              _Legend(color: AppColors.expense, label: 'Expense'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});
  final double height;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: height.clamp(4, 72),
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: context.appMuted)),
    ],
  );
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.rate, required this.saved});
  final double rate;
  final double saved;
  @override
  Widget build(BuildContext context) => PrototypeCard(
    child: Column(
      children: [
        Row(
          children: [
            Text(
              'Savings Rate',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '${(rate * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.income,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 8,
            backgroundColor: context.appBorder,
            valueColor: const AlwaysStoppedAnimation(AppColors.income),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'You saved ${CurrencyFormatter.format(saved)} this month 🎉',
            style: TextStyle(fontSize: 12, color: context.appMuted),
          ),
        ),
      ],
    ),
  );
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final search = TextEditingController();
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() => context.read<TransactionProvider>().load({
    'search': search.text,
    'type': filter == 'all' ? null : filter,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const PrototypeBottomNav(
      active: AppRoutes.transactions,
    ),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: context.appCard,
              border: Border(bottom: BorderSide(color: context.appBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Search transactions...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _load,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final f in ['all', 'income', 'expense']) ...[
                      _FilterChip(
                        label: f,
                        selected: filter == f,
                        onTap: () {
                          setState(() => filter = f);
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    _OutlinePill(label: '⚙ Filter', onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (_, state, __) {
                if (state.loading && state.transactions.isEmpty)
                  return const LoadingWidget();
                if (state.transactions.isEmpty)
                  return const PrototypeEmptyState(
                    icon: '🔍',
                    title: 'No transactions found',
                    subtitle: 'Try adjusting your filters or search terms.',
                  );
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (_, i) => PrototypeTransactionCard(
                      transaction: state.transactions[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.transactionDetails,
                        arguments: state.transactions[i],
                      ),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: state.transactions.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : context.appBorder,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : context.appMuted,
        ),
      ),
    ),
  );
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.appMuted,
        ),
      ),
    ),
  );
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.transaction});
  final TransactionModel? transaction;
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  final title = TextEditingController();
  String type = 'expense';
  String method = 'Cash';
  int? accountId;
  int? categoryId;
  DateTime date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    if (tx != null) {
      amount.text = tx.amount.toStringAsFixed(0);
      note.text = tx.note ?? tx.title;
      title.text = tx.title;
      type = tx.type;
      method = tx.paymentMethod ?? 'Cash';
      accountId = tx.account?.id;
      categoryId = tx.category?.id;
      date = tx.transactionDate;
    }
    Future.microtask(() async {
      await context.read<AccountProvider>().load();
      await context.read<CategoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && widget.transaction == null) type = arg;
    return Scaffold(
      appBar: PrototypeTopBar(
        title: widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction',
        onBack: () => Navigator.pop(context),
      ),
      body: Consumer3<AccountProvider, CategoryProvider, TransactionProvider>(
        builder: (_, accounts, categories, txState, __) {
          final cats = categories.byType(type);
          return Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TypeToggle(
                  type: type,
                  onChanged: (v) => setState(() {
                    type = v;
                    categoryId = null;
                  }),
                ),
                const SizedBox(height: 14),
                PrototypeCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(fontSize: 13, color: context.appMuted),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '৳',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: context.appMuted,
                            ),
                          ),
                          SizedBox(
                            width: 170,
                            child: TextFormField(
                              controller: amount,
                              validator: Validators.amount,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: type == 'income'
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PrototypeInput(
                  controller: title,
                  label: 'Title',
                  placeholder: "What's this for?",
                  icon: Icons.edit_note,
                  validator: Validators.required,
                ),
                const SizedBox(height: 14),
                _ChipSection(
                  title: 'Account',
                  children: accounts.accounts
                      .map(
                        (a) => _SelectablePill(
                          label: a.name,
                          icon: '💳',
                          selected: accountId == a.id,
                          onTap: () => setState(() => accountId = a.id),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                _ChipSection(
                  title: 'Category',
                  children: cats
                      .map(
                        (c) => CategoryChipTile(
                          category: c,
                          selected: categoryId == c.id,
                          onTap: () => setState(() => categoryId = c.id),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                _ChipSection(
                  title: 'Payment Method',
                  children: ['Cash', 'Bank Transfer', 'Card', 'Wallet']
                      .map(
                        (m) => _MethodPill(
                          label: m,
                          selected: method == m,
                          onTap: () => setState(() => method = m),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                PrototypeInput(
                  controller: TextEditingController(
                    text: DateFormatter.api(date),
                  ),
                  label: 'Date',
                  icon: Icons.calendar_month,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: date,
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                ),
                const SizedBox(height: 14),
                PrototypeInput(
                  controller: note,
                  label: 'Note',
                  placeholder: 'Optional note',
                  icon: Icons.notes,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.appBorder,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '📎 Attach Receipt (optional)',
                      style: TextStyle(fontSize: 14, color: context.appMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (txState.error != null)
                  Text(
                    txState.error!,
                    style: TextStyle(color: AppColors.expense),
                  ),
                PrototypeButton(
                  label: 'Save Transaction',
                  variant: type == 'income'
                      ? ButtonVariant.income
                      : ButtonVariant.expense,
                  onPressed: txState.loading
                      ? null
                      : () async {
                          if (!form.currentState!.validate() ||
                              accountId == null ||
                              categoryId == null)
                            return;
                          await txState.save({
                            'title': title.text,
                            'amount': double.parse(amount.text),
                            'type': type,
                            'account_id': accountId,
                            'category_id': categoryId,
                            'transaction_date': DateFormatter.api(date),
                            'payment_method': method,
                            'note': note.text,
                          }, widget.transaction?.id);
                          if (mounted && txState.error == null) {
                            await context.read<DashboardProvider>().load();
                            Navigator.pop(context);
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});
  final String type;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.appBorder,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: ['expense', 'income'].map((t) {
        final selected = type == t;
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(t),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: selected
                    ? (t == 'income' ? AppColors.income : AppColors.expense)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                t == 'income' ? '↑ Income' : '↓ Expense',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : context.appMuted,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.appMuted,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: children),
    ],
  );
}

class _SelectablePill extends StatelessWidget {
  const _SelectablePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? context.appPrimarySoft : context.appCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primary : context.appBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.primary : context.appMuted,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? context.appPrimarySoft : context.appCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primary : context.appBorder,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : context.appMuted,
        ),
      ),
    ),
  );
}

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final tx = ModalRoute.of(context)!.settings.arguments as TransactionModel;
    final isIncome = tx.type == 'income';
    return Scaffold(
      appBar: PrototypeTopBar(
        title: 'Transaction Detail',
        onBack: () => Navigator.pop(context),
        right: TextButton(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.editTransaction,
            arguments: tx,
          ),
          child: Text('Edit'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PrototypeCard(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? context.appIncomeSoft
                        : context.appExpenseSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      iconForTransaction(tx),
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isIncome ? 'Income' : 'Expense',
                  style: TextStyle(fontSize: 13, color: context.appMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isIncome ? AppColors.income : AppColors.expense,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tx.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.appText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PrototypeCard(
            child: Column(
              children: [
                _DetailRow(
                  'Category',
                  '${iconForTransaction(tx)} ${tx.category?.name ?? tx.type}',
                ),
                _DetailRow('Date', DateFormatter.display(tx.transactionDate)),
                _DetailRow('Payment', tx.paymentMethod ?? '-'),
                const _DetailRow('Status', '✅ Completed'),
                _DetailRow(
                  'Note',
                  tx.note?.isNotEmpty == true ? tx.note! : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PrototypeButton(
                  label: '✏️ Edit',
                  variant: ButtonVariant.outline,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.editTransaction,
                    arguments: tx,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrototypeButton(
                  label: '🗑 Delete',
                  variant: ButtonVariant.expense,
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Delete transaction?'),
                        content: Text(
                          'This will reverse the account balance effect.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await context.read<TransactionProvider>().remove(tx.id);
                      await context.read<DashboardProvider>().load();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.appBorder)),
    ),
    child: Row(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: context.appMuted)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appText,
            ),
          ),
        ),
      ],
    ),
  );
}

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AccountProvider>().load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Accounts',
      onBack: () => Navigator.pop(context),
      right: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addAccount),
        icon: const Icon(Icons.add, color: AppColors.primary),
      ),
    ),
    body: Consumer<AccountProvider>(
      builder: (_, state, __) {
        if (state.loading && state.accounts.isEmpty)
          return const LoadingWidget();
        if (state.accounts.isEmpty)
          return const PrototypeEmptyState(
            icon: '💳',
            title: 'No accounts yet',
            subtitle: 'Add a wallet, bank, card, or mobile banking account.',
          );
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: state.accounts.map((a) => AccountCard(account: a)).toList(),
        );
      },
    ),
  );
}

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});
  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      balance = TextEditingController(text: '0');
  String type = 'cash';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Add Account',
      onBack: () => Navigator.pop(context),
    ),
    body: Consumer<AccountProvider>(
      builder: (_, state, __) => Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PrototypeInput(
              controller: name,
              label: 'Account Name',
              placeholder: 'Cash Wallet',
              icon: Icons.account_balance_wallet,
              validator: Validators.required,
            ),
            const SizedBox(height: 14),
            _ChipSection(
              title: 'Account Type',
              children: ['cash', 'bank', 'mobile_banking', 'card', 'other']
                  .map(
                    (t) => _SelectablePill(
                      label: t.replaceAll('_', ' '),
                      icon: '💳',
                      selected: type == t,
                      onTap: () => setState(() => type = t),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: balance,
              label: 'Opening Balance',
              prefix: '৳ ',
              keyboardType: TextInputType.number,
              validator: Validators.amount,
            ),
            const SizedBox(height: 18),
            PrototypeButton(
              label: 'Save Account',
              onPressed: state.loading
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      await state.save({
                        'name': name.text,
                        'type': type,
                        'opening_balance': double.parse(balance.text),
                      });
                      if (mounted && state.error == null)
                        Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    ),
  );
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String tab = 'expense';
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CategoryProvider>().load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: context.appCard,
              border: Border(bottom: BorderSide(color: context.appBorder)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.addCategory),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['expense', 'income'].map((t) {
                      final selected = tab == t;
                      return Expanded(
                        child: InkWell(
                          onTap: () => setState(() => tab = t),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: selected
                                  ? context.appCard
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: selected
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x12000000),
                                        blurRadius: 12,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              t == 'income' ? '↑ Income' : '↓ Expense',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? context.appText
                                    : context.appMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (_, state, __) {
                final cats = state.byType(tab);
                if (cats.isEmpty)
                  return const PrototypeEmptyState(
                    icon: '🏷',
                    title: 'No categories',
                    subtitle: 'Create a category to organize transactions.',
                  );
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, i) =>
                      _CategoryCard(category: cats[i], tab: tab),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: cats.length,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.tab});
  final CategoryModel category;
  final String tab;
  @override
  Widget build(BuildContext context) {
    final color = colorForCategory(category);
    return PrototypeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => Navigator.pushNamed(context, AppRoutes.addCategory),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                iconForCategory(category),
                style: TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (tab == 'expense')
                  Text(
                    'Budget: set monthly limit',
                    style: TextStyle(fontSize: 12, color: context.appMuted),
                  ),
              ],
            ),
          ),
          _MiniIcon(
            color: context.appPrimarySoft,
            icon: Icons.edit,
            iconColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          _MiniIcon(
            color: context.appExpenseSoft,
            icon: Icons.delete_outline,
            iconColor: AppColors.expense,
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({
    required this.color,
    required this.icon,
    required this.iconColor,
  });
  final Color color;
  final IconData icon;
  final Color iconColor;
  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, size: 15, color: iconColor),
  );
}

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});
  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  String selectedIcon = '🛒';
  Color selectedColor = AppColors.income;
  String type = 'expense';
  final icons = const [
    '🛒',
    '🚗',
    '⚡',
    '🏠',
    '🏥',
    '📺',
    '🛍',
    '📚',
    '✈️',
    '🎮',
    '💊',
    '🎁',
    '🍔',
    '☕',
  ];
  final colors = const [
    AppColors.income,
    AppColors.expense,
    AppColors.primary,
    AppColors.warning,
    AppColors.categoryPink,
    AppColors.categoryBlue,
    AppColors.categoryOrange,
    AppColors.categoryPurple,
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Add Category',
      onBack: () => Navigator.pop(context),
    ),
    body: Consumer<CategoryProvider>(
      builder: (_, state, __) => Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: .12),
                  border: Border.all(color: selectedColor, width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(selectedIcon, style: TextStyle(fontSize: 40)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrototypeInput(
              controller: name,
              label: 'Category Name',
              placeholder: 'e.g. Entertainment',
              icon: Icons.sell_outlined,
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            _ChipSection(
              title: 'Choose Icon',
              children: icons
                  .map(
                    (ic) => InkWell(
                      onTap: () => setState(() => selectedIcon = ic),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selectedIcon == ic
                              ? context.appPrimarySoft
                              : context.appCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedIcon == ic
                                ? AppColors.primary
                                : context.appBorder,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(ic, style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _ChipSection(
              title: 'Choose Color',
              children: colors
                  .map(
                    (c) => InkWell(
                      onTap: () => setState(() => selectedColor = c),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedColor == c
                                ? context.appText
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _ChipSection(
              title: 'Type',
              children: [
                SizedBox(
                  width: 150,
                  child: PrototypeButton(
                    label: '↑ Income',
                    variant: ButtonVariant.income,
                    onPressed: () => setState(() => type = 'income'),
                    height: 46,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: PrototypeButton(
                    label: '↓ Expense',
                    variant: ButtonVariant.expense,
                    onPressed: () => setState(() => type = 'expense'),
                    height: 46,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrototypeButton(
              label: 'Save Category',
              onPressed: state.loading
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      await state.save({
                        'name': name.text,
                        'type': type,
                        'icon': selectedIcon,
                        'color':
                            '#${selectedColor.toARGB32().toRadixString(16).substring(2)}',
                      });
                      if (mounted && state.error == null)
                        Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    ),
  );
}

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});
  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<BudgetProvider>().load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: context.appCard,
              border: Border(bottom: BorderSide(color: context.appBorder)),
            ),
            child: Row(
              children: [
                Text(
                  'Budget',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.appText,
                  ),
                ),
                const Spacer(),
                PrototypeButton(
                  label: '+ Set Budget',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.addBudget),
                  fullWidth: false,
                  height: 36,
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<BudgetProvider>(
              builder: (_, state, __) {
                final totalBudget = state.budgets.fold<double>(
                  0,
                  (sum, b) => sum + b.amount,
                );
                final totalSpent = state.budgets.fold<double>(
                  0,
                  (sum, b) => sum + b.spent,
                );
                final pct = totalBudget <= 0
                    ? 0.0
                    : (totalSpent / totalBudget).clamp(0.0, 1.0);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PrototypeCard(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Budget',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(totalBudget),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Spent',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(totalSpent),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '${(pct * 100).round()}% used',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${CurrencyFormatter.format(totalBudget - totalSpent)} remaining',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Category Budgets',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (state.budgets.isEmpty)
                      const PrototypeEmptyState(
                        icon: '🎯',
                        title: 'No budgets yet',
                        subtitle: 'Set category budgets to track spending.',
                      )
                    else
                      ...state.budgets.map((b) {
                        final progress = b.amount <= 0
                            ? 0.0
                            : (b.spent / b.amount).clamp(0.0, 1.0);
                        final over = b.spent > b.amount;
                        final color = b.category == null
                            ? AppColors.primary
                            : colorForCategory(b.category!);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PrototypeCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: .12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          b.category == null
                                              ? '🏷'
                                              : iconForCategory(b.category!),
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                b.category?.name ?? 'Budget',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Spacer(),
                                              if (over)
                                                PrototypeTag(
                                                  label: 'Over!',
                                                  color: AppColors.expense,
                                                  background:
                                                      context.appExpenseSoft,
                                                ),
                                            ],
                                          ),
                                          Text(
                                            '${CurrencyFormatter.format(b.spent)} / ${CurrencyFormatter.format(b.amount)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: context.appMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: context.appBorder,
                                    valueColor: AlwaysStoppedAnimation(
                                      over ? AppColors.expense : color,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '${(progress * 100).round()}% used',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.appMuted,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      over
                                          ? '${CurrencyFormatter.format(b.spent - b.amount)} over budget'
                                          : '${CurrencyFormatter.format(b.amount - b.spent)} left',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: over
                                            ? AppColors.expense
                                            : AppColors.income,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});
  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  int? categoryId;
  int month = DateTime.now().month;
  int year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<CategoryProvider>().load(type: 'expense'),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Set Budget',
      onBack: () => Navigator.pop(context),
    ),
    body: Consumer2<CategoryProvider, BudgetProvider>(
      builder: (_, cats, budgets, __) => Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ChipSection(
              title: 'Expense Category',
              children: cats
                  .byType('expense')
                  .map(
                    (c) => CategoryChipTile(
                      category: c,
                      selected: categoryId == c.id,
                      onTap: () => setState(() => categoryId = c.id),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: amount,
              label: 'Budget Amount',
              prefix: '৳ ',
              keyboardType: TextInputType.number,
              validator: Validators.amount,
            ),
            const SizedBox(height: 14),
            _ChipSection(
              title: 'Month',
              children: List.generate(
                12,
                (i) => _FilterChip(
                  label: '${i + 1}',
                  selected: month == i + 1,
                  onTap: () => setState(() => month = i + 1),
                ),
              ),
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: TextEditingController(text: '$year'),
              label: 'Year',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),
            PrototypeButton(
              label: 'Save Budget',
              onPressed: budgets.loading
                  ? null
                  : () async {
                      if (!form.currentState!.validate() || categoryId == null)
                        return;
                      await budgets.save({
                        'category_id': categoryId,
                        'amount': double.parse(amount.text),
                        'month': month,
                        'year': year,
                      });
                      if (mounted && budgets.error == null)
                        Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    ),
  );
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PremiumAnalyticsScreen();
}

class _LegacyReportsScreen extends StatefulWidget {
  const _LegacyReportsScreen();
  @override
  State<_LegacyReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<_LegacyReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<DashboardProvider>().load();
      await context.read<ReportProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const PrototypeBottomNav(active: AppRoutes.reports),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: context.appCard,
              border: Border(bottom: BorderSide(color: context.appBorder)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Reports',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _RangePill(label: '📤 Export', selected: true),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RangePill(label: 'This Month', selected: true),
                    SizedBox(width: 6),
                    _RangePill(label: '3 Months'),
                    SizedBox(width: 6),
                    _RangePill(label: 'This Year'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer2<DashboardProvider, ReportProvider>(
              builder: (_, dash, reports, __) {
                final d = dash.dashboard;
                if (dash.loading && d == null) return const LoadingWidget();
                final income = d?.monthlyIncome ?? 0;
                final expense = d?.monthlyExpense ?? 0;
                final net = income - expense;
                final catRows = reports.categories.whereType<Map>().toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Income',
                            value: income,
                            icon: Icons.arrow_upward,
                            color: AppColors.income,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SummaryCard(
                            title: 'Expenses',
                            value: expense,
                            icon: Icons.arrow_downward,
                            color: AppColors.expense,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SummaryCard(
                            title: 'Net',
                            value: net,
                            icon: Icons.drag_handle,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    PrototypeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense Breakdown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              SizedBox(
                                width: 124,
                                height: 124,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 38,
                                    sections: _pieSections(catRows),
                                    centerSpaceColor: context.appCard,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(children: _legendRows(catRows)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrototypeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income vs Expense',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ReportBar(
                            label: 'Income',
                            value: income,
                            max: math.max(income, expense),
                            color: AppColors.income,
                          ),
                          const SizedBox(height: 10),
                          _ReportBar(
                            label: 'Expense',
                            value: expense,
                            max: math.max(income, expense),
                            color: AppColors.expense,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrototypeCard(
                      gradient: const LinearGradient(
                        colors: [AppColors.income, Color(0xFF13986A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Net Profit / Saving',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${net >= 0 ? '+' : '-'}${CurrencyFormatter.format(net.abs())}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  income <= 0
                                      ? 'No income this month'
                                      : '${((net / income) * 100).round()}% savings rate 🎉',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text('📈', style: TextStyle(fontSize: 48)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  List<PieChartSectionData> _pieSections(List<Map> rows) {
    final colors = [
      AppColors.primary,
      AppColors.income,
      AppColors.warning,
      AppColors.categoryBlue,
      AppColors.expense,
      context.appFaint,
    ];
    if (rows.isEmpty)
      return [
        PieChartSectionData(
          value: 1,
          color: context.appBorder,
          showTitle: false,
          radius: 20,
        ),
      ];
    return List.generate(
      rows.length.clamp(0, 6),
      (i) => PieChartSectionData(
        value: double.tryParse('${rows[i]['total']}') ?? 1,
        color: colors[i % colors.length],
        showTitle: false,
        radius: 22,
      ),
    );
  }

  List<Widget> _legendRows(List<Map> rows) {
    final colors = [
      AppColors.primary,
      AppColors.income,
      AppColors.warning,
      AppColors.categoryBlue,
      AppColors.expense,
      context.appFaint,
    ];
    if (rows.isEmpty)
      return [
        Text(
          'No category data',
          style: TextStyle(fontSize: 11, color: context.appMuted),
        ),
      ];
    return List.generate(rows.length.clamp(0, 6), (i) {
      final row = rows[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                row['category']?['name']?.toString() ?? 'Category',
                style: TextStyle(fontSize: 11, color: context.appMuted),
              ),
            ),
            Text(
              CurrencyFormatter.format(double.tryParse('${row['total']}') ?? 0),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    });
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill({required this.label, this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: selected ? AppColors.primary : context.appBorder,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : context.appMuted,
      ),
    ),
  );
}

class _ReportBar extends StatelessWidget {
  const _ReportBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });
  final String label;
  final double value;
  final double max;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: context.appMuted)),
          const Spacer(),
          Text(
            CurrencyFormatter.format(value),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: max <= 0 ? 0 : value / max,
          minHeight: 8,
          backgroundColor: context.appBorder,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ],
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Profile',
      onBack: () => Navigator.pop(context),
    ),
    body: Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final user = auth.user;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PrototypeCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                    ),
                    child: Center(
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'A')
                            .toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Alex Johnson',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user?.email ?? 'alex@email.com',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrototypeCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    icon: '👤',
                    label: 'Edit Profile',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.editProfile),
                  ),
                  _SettingsRow(
                    icon: '💱',
                    label: 'Currency',
                    value: user?.currency ?? 'BDT',
                  ),
                  _SettingsRow(
                    icon: '🔐',
                    label: 'Change Password',
                    onTap: () => _changePassword(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrototypeButton(
              label: 'Sign Out',
              variant: ButtonVariant.expense,
              onPressed: () async {
                await auth.logout();
                if (context.mounted)
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (_) => false,
                  );
              },
            ),
          ],
        );
      },
    ),
  );

  void _changePassword(BuildContext context) {
    final current = TextEditingController(),
        password = TextEditingController(),
        confirmation = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrototypeInput(
              controller: current,
              label: 'Current Password',
              obscureText: true,
            ),
            const SizedBox(height: 12),
            PrototypeInput(
              controller: password,
              label: 'New Password',
              obscureText: true,
            ),
            const SizedBox(height: 12),
            PrototypeInput(
              controller: confirmation,
              label: 'Confirm Password',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await context.read<AuthProvider>().changePassword({
                'current_password': current.text,
                'password': password.text,
                'password_confirmation': confirmation.text,
              });
              if (context.mounted && ok) Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, email, phone, currency;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    name = TextEditingController(text: user?.name);
    email = TextEditingController(text: user?.email);
    phone = TextEditingController(text: user?.phone);
    currency = TextEditingController(text: user?.currency ?? 'BDT');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Edit Profile',
      onBack: () => Navigator.pop(context),
    ),
    body: Consumer<AuthProvider>(
      builder: (_, auth, __) => Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PrototypeInput(
              controller: name,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: Validators.required,
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: email,
              label: 'Email',
              icon: Icons.mail_outline,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: phone,
              label: 'Phone',
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: currency,
              label: 'Currency',
              icon: Icons.currency_exchange,
              validator: Validators.required,
            ),
            const SizedBox(height: 18),
            if (auth.error != null)
              Text(auth.error!, style: TextStyle(color: AppColors.expense)),
            PrototypeButton(
              label: auth.loading ? 'Saving...' : 'Save Profile',
              onPressed: auth.loading
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      final ok = await auth.updateProfile({
                        'name': name.text,
                        'email': email.text,
                        'phone': phone.text,
                        'currency': currency.text,
                      });
                      if (mounted && ok) Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool dark = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const PrototypeBottomNav(active: AppRoutes.settings),
    body: SafeArea(
      bottom: false,
      child: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          final user = auth.user;
          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: context.appCard,
                  border: Border(bottom: BorderSide(color: context.appBorder)),
                ),
                child: Text(
                  'Settings',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: PrototypeCard(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                        ),
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty == true
                                    ? user!.name[0]
                                    : 'A')
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Alex Johnson',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              user?.email ?? 'alex@email.com',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.appMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PrototypeButton(
                        label: 'Edit',
                        variant: ButtonVariant.secondary,
                        fullWidth: false,
                        height: 34,
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.profile),
                      ),
                    ],
                  ),
                ),
              ),
              _SettingsSection(
                title: 'Account',
                rows: [
                  _SettingsRow(
                    icon: '👤',
                    label: 'Edit Profile',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.profile),
                  ),
                  const _SettingsRow(icon: '🔔', label: 'Notifications'),
                  _SettingsRow(
                    icon: '💱',
                    label: 'Currency',
                    value: user?.currency ?? 'BDT',
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Preferences',
                rows: [
                  _SettingsRow(
                    icon: '🌙',
                    label: 'Dark Mode',
                    trailing: _Toggle(
                      value: dark,
                      onTap: () => setState(() => dark = !dark),
                    ),
                  ),
                  const _SettingsRow(
                    icon: '🔐',
                    label: 'App Lock',
                    subtitle: 'PIN / Biometric',
                  ),
                  const _SettingsRow(
                    icon: '🌐',
                    label: 'Language',
                    value: 'English',
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Data',
                rows: [
                  _SettingsRow(
                    icon: '🎯',
                    label: 'Budgets',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.budgets),
                  ),
                  _SettingsRow(
                    icon: '🐷',
                    label: 'Savings Goals',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.goals),
                  ),
                  _SettingsRow(
                    icon: '💳',
                    label: 'Accounts',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.accounts),
                  ),
                  _SettingsRow(
                    icon: '🏷',
                    label: 'Categories',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.categories),
                  ),
                  const _SettingsRow(icon: '📤', label: 'Export CSV'),
                ],
              ),
              const _SettingsSection(
                title: 'More',
                rows: [
                  _SettingsRow(icon: '⭐', label: 'Rate App'),
                  _SettingsRow(icon: '📋', label: 'Privacy Policy'),
                  _SettingsRow(
                    icon: 'ℹ️',
                    label: 'App Version',
                    value: '1.0.0',
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: PrototypeButton(
                  label: 'Sign Out',
                  variant: ButtonVariant.expense,
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted)
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (_) => false,
                      );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrototypeSectionLabel(title),
        PrototypeCard(
          padding: EdgeInsets.zero,
          child: Column(children: rows),
        ),
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
  });
  final String icon;
  final String label;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.appBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(icon, style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: context.appText),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 11, color: context.appFaint),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (value != null)
            Text(
              value!,
              style: TextStyle(fontSize: 13, color: context.appMuted),
            )
          else if (onTap != null)
            Text('›', style: TextStyle(fontSize: 18, color: context.appFaint)),
        ],
      ),
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onTap});
  final bool value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? AppColors.primary : context.appBorder,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}
