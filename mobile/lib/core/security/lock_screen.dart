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
  String? error;
  bool biometricAvailable = false;
  bool hasPin = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final lock = context.read<AppLockService>();
      final available = await lock.canUseBiometrics();
      final pinExists = await lock.hasPin();
      if (mounted)
        setState(() {
          biometricAvailable = available;
          hasPin = pinExists;
        });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Locked',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 14),
                if (biometricAvailable &&
                    context.watch<AppLockService>().biometricEnabled) ...[
                  PrototypeButton(
                    label: 'Unlock with Fingerprint',
                    icon: Icons.fingerprint,
                    onPressed: () async {
                      final ok = await context
                          .read<AppLockService>()
                          .unlockWithBiometric();
                      if (!ok && mounted)
                        setState(
                          () => error =
                              'Fingerprint unlock failed. Use PIN instead.',
                        );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasPin) ...[
                  PrototypeInput(
                    controller: pin,
                    label: 'PIN',
                    icon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  PrototypeButton(
                    label: 'Unlock',
                    onPressed: () async {
                      final ok = await context
                          .read<AppLockService>()
                          .unlockWithPin(pin.text.trim());
                      if (!ok && mounted)
                        setState(() => error = 'Incorrect PIN.');
                    },
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                ],
              ],
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
    if (state == AppLifecycleState.resumed) {
      context.read<AppLockService>().lock();
    }
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
