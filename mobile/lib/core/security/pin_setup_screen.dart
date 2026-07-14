import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../../presentation/widgets/app_widgets.dart';
import 'app_lock_service.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final pin = TextEditingController();
  final confirm = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Set PIN',
      onBack: () => Navigator.pop(context, false),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          children: [
            const AppLogo(width: 160),
            const SizedBox(height: 24),
            PrototypeInput(
              controller: pin,
              label: '4-digit PIN',
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            PrototypeInput(
              controller: confirm,
              label: 'Confirm PIN',
              icon: Icons.lock_outline,
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(error!, style: TextStyle(color: AppColors.expense)),
              ),
            ],
            const SizedBox(height: 16),
            PrototypeButton(
              label: 'Save PIN',
              onPressed: () async {
                final value = pin.text.trim();
                if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                  setState(() => error = 'PIN must be exactly 4 digits.');
                  return;
                }
                if (value != confirm.text.trim()) {
                  setState(() => error = 'PINs do not match.');
                  return;
                }
                await context.read<AppLockService>().savePin(value);
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
