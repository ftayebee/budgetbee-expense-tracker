import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../../presentation/widgets/app_widgets.dart';
import 'app_lock_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  static const _pinLength = 4;
  String _pin = '';
  String? _error;
  bool _biometricAvailable = false;
  bool _hasPin = false;
  bool _processing = false;
  bool _attemptedAutomaticAuthentication = false;
  int _failedPinAttempts = 0;
  DateTime? _retryPinAfter;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    Future.microtask(_initializeUnlockOptions);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _initializeUnlockOptions() async {
    final lock = context.read<AppLockService>();
    final available = await lock.canUseBiometrics();
    final pinExists = await lock.hasPin();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _hasPin = pinExists;
    });
    if (available &&
        lock.biometricEnabled &&
        !_attemptedAutomaticAuthentication) {
      _attemptedAutomaticAuthentication = true;
      await _authenticateWithDevice();
    }
  }

  Future<void> _authenticateWithDevice() async {
    if (!mounted || context.read<AppLockService>().isAuthenticating) return;
    setState(() => _error = null);
    final result = await context.read<AppLockService>().unlockWithBiometric();
    if (!mounted || result == DeviceAuthenticationResult.success) return;
    setState(() {
      _error = switch (result) {
        DeviceAuthenticationResult.cancelled =>
          'Authentication cancelled. Enter your PIN or try again.',
        DeviceAuthenticationResult.unavailable =>
          'Device authentication is unavailable. Enter your PIN.',
        DeviceAuthenticationResult.failed =>
          'Authentication failed. Enter your PIN or try again.',
        DeviceAuthenticationResult.error =>
          'Could not authenticate. Enter your PIN.',
        DeviceAuthenticationResult.success => null,
      };
    });
  }

  void _enterDigit(String digit) {
    if (_processing || _pin.length >= _pinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      _pin += digit;
    });
  }

  void _backspace() {
    if (_processing || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submitPin() async {
    if (_processing || _pin.length != _pinLength) return;
    final retryAfter = _retryPinAfter;
    if (retryAfter != null && DateTime.now().isBefore(retryAfter)) {
      final seconds = retryAfter.difference(DateTime.now()).inSeconds + 1;
      setState(() => _error = 'Please wait $seconds seconds before retrying.');
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });
    final valid = await context.read<AppLockService>().unlockWithPin(_pin);
    if (!mounted || valid) return;
    _failedPinAttempts++;
    if (_failedPinAttempts >= 3) {
      _retryPinAfter = DateTime.now().add(const Duration(seconds: 5));
      Future<void>.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() {});
      });
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _processing = false;
      _pin = '';
      _error = _failedPinAttempts >= 3
          ? 'Incorrect PIN. Please wait 5 seconds before retrying.'
          : 'Incorrect PIN. Try again.';
    });
    await _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockService>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.darkStage,
        body: Stack(
          children: [
            Positioned(
              top: -180,
              left: -100,
              right: -100,
              child: Container(
                height: 390,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: .22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const BudgetBeeBrand(
                          size: BrandSize.compact,
                          showSlogan: false,
                          centered: true,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .14),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: .32),
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: AppColors.primaryLight,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your PIN to unlock BudgetBee',
                          style: TextStyle(
                            color: AppColors.darkMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: _shake,
                          builder: (context, child) {
                            final offset = _shake.isAnimating
                                ? math.sin(_shake.value * math.pi * 8) *
                                      (1 - _shake.value) *
                                      9
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: BudgetBeePinIndicator(
                            length: _pinLength,
                            filled: _pin.length,
                          ),
                        ),
                        SizedBox(
                          height: 34,
                          child: Center(
                            child: _error == null
                                ? null
                                : Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.expense,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        if (_hasPin)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 330),
                            child: BudgetBeeNumericKeypad(
                              onDigit: _enterDigit,
                              onBackspace: _backspace,
                              onBiometric:
                                  _biometricAvailable && lock.biometricEnabled
                                  ? _authenticateWithDevice
                                  : null,
                              enabled: !_processing && !lock.isAuthenticating,
                            ),
                          ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 330),
                          child: PrototypeButton(
                            label: _processing || lock.isAuthenticating
                                ? 'Unlocking…'
                                : 'Unlock BudgetBee',
                            onPressed: _processing || _pin.length != _pinLength
                                ? null
                                : _submitPin,
                          ),
                        ),
                        if (_biometricAvailable && lock.biometricEnabled) ...[
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: lock.isAuthenticating
                                ? null
                                : _authenticateWithDevice,
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: const Text('Use biometrics'),
                          ),
                        ],
                      ],
                    ),
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

class BudgetBeePinIndicator extends StatelessWidget {
  const BudgetBeePinIndicator({
    super.key,
    required this.length,
    required this.filled,
  });
  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$filled of $length PIN digits entered',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final active = index < filled;
        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: active ? 1 : .9,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: .16)
                  : AppColors.darkSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.darkBorder,
                width: 1.4,
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: active ? 12 : 8,
                height: active ? 12 : 8,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryLight : AppColors.darkBorder,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

class BudgetBeeNumericKeypad extends StatelessWidget {
  const BudgetBeeNumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final keys = <Object>[
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      Icons.fingerprint_rounded,
      0,
      Icons.backspace_outlined,
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 52,
        mainAxisSpacing: 8,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final keyValue = keys[index];
        final isBiometric = keyValue == Icons.fingerprint_rounded;
        final isBackspace = keyValue == Icons.backspace_outlined;
        final callback = !enabled
            ? null
            : isBiometric
            ? onBiometric
            : isBackspace
            ? onBackspace
            : () => onDigit('$keyValue');
        final label = isBiometric
            ? 'Use biometrics'
            : isBackspace
            ? 'Delete digit'
            : '$keyValue';
        return Semantics(
          button: true,
          label: label,
          child: Material(
            color: isBiometric && onBiometric == null
                ? Colors.transparent
                : AppColors.darkSurface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: callback,
              borderRadius: BorderRadius.circular(18),
              overlayColor: WidgetStatePropertyAll(
                AppColors.primary.withValues(alpha: .25),
              ),
              child: Center(
                child: keyValue is int
                    ? Text(
                        '$keyValue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Icon(
                        keyValue as IconData,
                        color: callback == null
                            ? AppColors.darkBorder
                            : AppColors.primaryLight,
                        size: 25,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
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
