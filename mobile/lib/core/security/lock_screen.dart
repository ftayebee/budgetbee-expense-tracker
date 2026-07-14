import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../../presentation/widgets/app_widgets.dart';
import 'app_lock_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final pin = TextEditingController();
  final pinFocus = FocusNode();
  String? error;
  bool biometricAvailable = false;
  bool hasPin = false;
  bool showPin = false;
  bool processingPin = false;
  bool attemptedAutomaticAuthentication = false;
  int failedPinAttempts = 0;
  DateTime? retryPinAfter;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initializeUnlockOptions);
  }

  @override
  void dispose() {
    pin.dispose();
    pinFocus.dispose();
    super.dispose();
  }

  Future<void> _initializeUnlockOptions() async {
    final lock = context.read<AppLockService>();
    final available = await lock.canUseBiometrics();
    final pinExists = await lock.hasPin();
    if (!mounted) return;
    setState(() {
      biometricAvailable = available;
      hasPin = pinExists;
      showPin = !available || !lock.biometricEnabled;
    });
    if (available &&
        lock.biometricEnabled &&
        !attemptedAutomaticAuthentication) {
      attemptedAutomaticAuthentication = true;
      await _authenticateWithDevice();
    }
  }

  Future<void> _authenticateWithDevice() async {
    if (!mounted) return;
    setState(() => error = null);
    final result = await context.read<AppLockService>().unlockWithBiometric();
    if (!mounted || result == DeviceAuthenticationResult.success) return;
    setState(() {
      error = switch (result) {
        DeviceAuthenticationResult.cancelled =>
          'Authentication was cancelled. Try again or use your PIN.',
        DeviceAuthenticationResult.unavailable =>
          'Device authentication is unavailable. Use your PIN instead.',
        DeviceAuthenticationResult.failed =>
          'Authentication failed. Try again or use your PIN.',
        DeviceAuthenticationResult.error =>
          'Device authentication could not be completed. Use your PIN.',
        DeviceAuthenticationResult.success => null,
      };
      showPin = hasPin;
    });
  }

  Future<void> _submitPin() async {
    if (processingPin || context.read<AppLockService>().isAuthenticating) {
      return;
    }
    final retryAfter = retryPinAfter;
    if (retryAfter != null && DateTime.now().isBefore(retryAfter)) {
      final seconds = retryAfter.difference(DateTime.now()).inSeconds + 1;
      setState(() => error = 'Please wait $seconds seconds before retrying.');
      return;
    }

    setState(() {
      processingPin = true;
      error = null;
    });
    final valid = await context.read<AppLockService>().unlockWithPin(
      pin.text.trim(),
    );
    if (!mounted) return;
    if (valid) {
      failedPinAttempts = 0;
      retryPinAfter = null;
      return;
    }

    failedPinAttempts++;
    if (failedPinAttempts >= 3) {
      retryPinAfter = DateTime.now().add(const Duration(seconds: 5));
      Future<void>.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() {});
      });
    }
    setState(() {
      processingPin = false;
      error = failedPinAttempts >= 3
          ? 'Incorrect PIN. Please wait 5 seconds before retrying.'
          : 'Incorrect PIN.';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: PrototypeCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(
                    width: (MediaQuery.sizeOf(context).width * .48)
                        .clamp(145.0, 220.0)
                        .toDouble(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'App Locked',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.appText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Authenticate to securely access your finances.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appMuted, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  if (biometricAvailable &&
                      context.watch<AppLockService>().biometricEnabled) ...[
                    PrototypeButton(
                      label: context.watch<AppLockService>().isAuthenticating
                          ? 'Authenticating...'
                          : 'Use device authentication',
                      icon: Icons.fingerprint,
                      onPressed:
                          context.watch<AppLockService>().isAuthenticating
                          ? null
                          : _authenticateWithDevice,
                    ),
                    const SizedBox(height: 12),
                    if (hasPin && !showPin)
                      TextButton(
                        onPressed: () {
                          setState(() => showPin = true);
                          pinFocus.requestFocus();
                        },
                        child: const Text('Use PIN instead'),
                      ),
                  ],
                  if (hasPin && showPin) ...[
                    PrototypeInput(
                      controller: pin,
                      focusNode: pinFocus,
                      label: 'PIN',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    PrototypeButton(
                      label: processingPin ? 'Verifying...' : 'Unlock',
                      onPressed: processingPin ? null : _submitPin,
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: TextStyle(color: AppColors.expense)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => context.read<AppLockService>().initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<AppLockService>().handleLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final locked = context.watch<AppLockService>().locked;
    return Stack(
      children: [
        widget.child,
        if (locked) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}
