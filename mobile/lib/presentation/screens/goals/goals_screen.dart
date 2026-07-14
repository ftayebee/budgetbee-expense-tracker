import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

/// Savings goals: create targets, track progress, and log contributions.
/// Backed by the `/savings-goals` API.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SavingsGoalProvider>().load());
  }

  Future<void> _refresh() => context.read<SavingsGoalProvider>().load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrototypeTopBar(
        title: 'Savings Goals',
        onBack: () => Navigator.pop(context),
        right: IconButton(
          icon: const Icon(Icons.add, color: AppColors.primary),
          tooltip: 'New goal',
          onPressed: _openGoalForm,
        ),
      ),
      body: Consumer<SavingsGoalProvider>(
        builder: (_, state, __) {
          if (state.loading && state.goals.isEmpty) {
            return const LoadingWidget();
          }
          if (state.error != null && state.goals.isEmpty) {
            return ErrorState(state.error!);
          }
          if (state.goals.isEmpty) {
            return const PrototypeEmptyState(
              icon: '🎯',
              title: 'No savings goals yet',
              subtitle: 'Create a goal to start tracking your progress.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  saved: state.totalSaved,
                  target: state.totalTarget,
                ),
                const SizedBox(height: 8),
                ...state.goals.map(
                  (g) => _GoalCard(
                    goal: g,
                    onContribute: () => _openContributeForm(g),
                    onDelete: () => _confirmDelete(g),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openGoalForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GoalFormSheet(),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Goal created.')));
    }
  }

  Future<void> _openContributeForm(SavingsGoalModel goal) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContributeSheet(goal: goal),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contribution added.')));
    }
  }

  Future<void> _confirmDelete(SavingsGoalModel goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text(
          'This permanently removes "${goal.name}" and its contribution history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<SavingsGoalProvider>().remove(goal.id);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.saved, required this.target});
  final double saved;
  final double target;

  @override
  Widget build(BuildContext context) {
    final pct = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);
    return PrototypeCard(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total saved',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(saved),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'of ${CurrencyFormatter.format(target)} across all goals',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onContribute,
    required this.onDelete,
  });
  final SavingsGoalModel goal;
  final VoidCallback onContribute;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress / 100).clamp(0.0, 1.0);
    return PrototypeCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.appText,
                  ),
                ),
              ),
              if (goal.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.appIncomeSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: AppColors.income,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                CurrencyFormatter.format(goal.currentAmount),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.appText,
                ),
              ),
              Text(
                '  /  ${CurrencyFormatter.format(goal.targetAmount)}',
                style: TextStyle(color: context.appMuted, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${goal.progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: context.appBorder,
              valueColor: AlwaysStoppedAnimation(
                goal.isCompleted ? AppColors.income : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.isCompleted
                      ? 'Goal reached 🎉'
                      : '${CurrencyFormatter.format(goal.remainingAmount)} to go'
                            '${goal.monthlyContributionNeeded != null ? ' · ${CurrencyFormatter.format(goal.monthlyContributionNeeded!)}/mo' : ''}',
                  style: TextStyle(color: context.appMuted, fontSize: 12),
                ),
              ),
              if (!goal.isCompleted)
                PrototypeButton(
                  label: '+ Add funds',
                  onPressed: onContribute,
                  fullWidth: false,
                  height: 34,
                  variant: ButtonVariant.secondary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet();

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  DateTime? _targetDate;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 20),
      initialDate: _targetDate ?? now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final provider = context.read<SavingsGoalProvider>();
    final ok = await provider.save({
      'name': _name.text.trim(),
      'target_amount': double.parse(_amount.text.trim()),
      if (_targetDate != null)
        'target_date':
            '${_targetDate!.year.toString().padLeft(4, '0')}-${_targetDate!.month.toString().padLeft(2, '0')}-${_targetDate!.day.toString().padLeft(2, '0')}',
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not save goal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'New savings goal',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrototypeInput(
              controller: _name,
              label: 'Goal name',
              placeholder: 'Emergency fund, Laptop, Travel…',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: _amount,
              label: 'Target amount',
              placeholder: '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: TextEditingController(
                text: _targetDate == null
                    ? ''
                    : '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
              ),
              label: 'Target date (optional)',
              placeholder: 'Select a date',
              icon: Icons.event,
              readOnly: true,
              onTap: _pickDate,
            ),
            const SizedBox(height: 20),
            PrototypeButton(
              label: _submitting ? 'Saving…' : 'Create goal',
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributeSheet extends StatefulWidget {
  const _ContributeSheet({required this.goal});
  final SavingsGoalModel goal;

  @override
  State<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<_ContributeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final provider = context.read<SavingsGoalProvider>();
    final ok = await provider.contribute(widget.goal.id, {
      'amount': double.parse(_amount.text.trim()),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Could not add contribution.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Add to ${widget.goal.name}',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${CurrencyFormatter.format(widget.goal.remainingAmount)} remaining',
              style: TextStyle(color: context.appMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              controller: _amount,
              label: 'Contribution amount',
              placeholder: '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),
            PrototypeButton(
              label: _submitting ? 'Adding…' : 'Add contribution',
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
