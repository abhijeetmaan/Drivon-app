import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../shared/dialogs/delete_confirmation.dart' show deleteSwipeBackground, showItemDeletedSnackbar, showPremiumDeleteDialog;
import '../../../../shared/selection/list_selection_controller.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/selectable_swipe_tile.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_providers.dart';
import '../utils/split_calculator.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  final ListSelectionController _expenseSelection = ListSelectionController();

  @override
  void dispose() {
    _expenseSelection.dispose();
    super.dispose();
  }

  Future<void> _bulkDeleteTripExpenses(Trip current) async {
    final ids = _expenseSelection.selectedIds.toList();
    if (ids.isEmpty) return;
    final n = ids.length;
    final ok = await showPremiumDeleteDialog(
      context,
      title: n == 1 ? 'Delete trip expense?' : 'Delete $n items?',
      onConfirm: () async {
        for (final id in ids) {
          await ref.read(tripActionsProvider).removeTripExpense(current, id);
        }
      },
      successMessage: n == 1 ? 'Trip expense deleted' : '$n items deleted',
    );
    if (ok && mounted) _expenseSelection.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);

    return ListenableBuilder(
      listenable: _expenseSelection,
      builder: (context, _) {
        return tripsAsync.when(
      loading: () => Scaffold(
            appBar: AppBar(title: Text(widget.trip.name)),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(height: 120, borderRadius: BorderRadius.all(Radius.circular(20))),
                  const SizedBox(height: AppSpacing.s16),
                  const Skeleton(height: 28, width: 120, borderRadius: BorderRadius.all(Radius.circular(8))),
                  const SizedBox(height: 12),
                  const Skeleton(height: 160, borderRadius: BorderRadius.all(Radius.circular(20))),
                  const SizedBox(height: 12),
                  for (var i = 0; i < 4; i++) ...[
                    const Skeleton(height: 56, borderRadius: BorderRadius.all(Radius.circular(16))),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
      error: (e, _) => Scaffold(appBar: AppBar(title: Text(widget.trip.name)), body: Center(child: Text('Failed: $e'))),
      data: (trips) {
        final current = trips.firstWhere((t) => t.id == widget.trip.id, orElse: () => widget.trip);
        final members = current.members;
        final expenses = current.expenses;

        final split = calculateEqualSplit(
          members: members,
          expenses: [
            for (final e in expenses) {'paidBy': e.paidBy, 'amount': e.amount}
          ],
        );

        return Scaffold(
          appBar: _expenseSelection.isActive
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _expenseSelection.clear();
                    },
                  ),
                  title: Text(
                    '${_expenseSelection.count} selected',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _expenseSelection.count == 0
                          ? null
                          : () => _bulkDeleteTripExpenses(current),
                    ),
                  ],
                )
              : AppBar(
                  title: Text(current.name),
                  actions: [
                    IconButton(
                      tooltip: 'Delete trip',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await showPremiumDeleteDialog(
                          context,
                          title: 'Delete Trip?',
                          onConfirm: () async {
                            await ref.read(tripActionsProvider).deleteTrip(current.id);
                          },
                          successMessage: 'Trip deleted',
                        );
                        if (ok && context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _TripSummaryCard(split: split, members: members, expensesCount: expenses.length),
              const SizedBox(height: 12),
              SectionHeader(
                title: 'Members',
                trailing: TextButton(onPressed: () => _showAddMember(context, ref, current), child: const Text('Add')),
              ),
              if (members.isEmpty)
                EmptyState(
                  icon: Icons.group_outlined,
                  title: 'Add members',
                  message: 'Add at least 2 members to split this trip.',
                  actionLabel: 'Add member',
                  onAction: () => _showAddMember(context, ref, current),
                )
              else ...[
                _MemberBalancesCard(members: members, balances: split.balanceByMember),
                const SizedBox(height: 10),
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Balance graph', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SizedBox(height: 140, child: _BalanceBarChart(balances: split.balanceByMember, members: members)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final m in members)
                      _MemberChip(
                        name: m,
                        onDelete: () async {
                          await showPremiumDeleteDialog(
                            context,
                            title: 'Remove member?',
                            onConfirm: () async {
                              await ref.read(tripActionsProvider).removeMember(current, m);
                            },
                            successMessage: 'Member removed',
                          );
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SectionHeader(
                title: 'Expenses',
                trailing: TextButton(
                  onPressed: members.isEmpty ? null : () => _showAddExpenseBottomSheet(context, ref, current),
                  child: const Text('Add'),
                ),
              ),
              if (expenses.isEmpty)
                CustomCard(
                  child: Text(members.isEmpty ? 'Add members first.' : 'No expenses yet. Add who paid and how much.'),
                )
              else
                _TripTimeline(
                  expenses: expenses,
                  selection: _expenseSelection,
                  deleteExpense: (ex) async {
                    await ref.read(tripActionsProvider).removeTripExpense(current, ex.id);
                  },
                ),
              const SizedBox(height: 12),
              const SectionHeader(title: 'Who owes whom'),
              if (members.length < 2 || split.total == 0)
                const CustomCard(child: Text('Add at least 2 members and some expenses.'))
              else if (split.settlements.isEmpty)
                const CustomCard(child: Text('All settled up.'))
              else
                ...split.settlements.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SettlementCard(s: s),
                  ),
                ),
            ],
          ),
        );
      },
    );
      },
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  final SplitResult split;
  final List<String> members;
  final int expensesCount;
  const _TripSummaryCard({required this.split, required this.members, required this.expensesCount});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.14),
            child: const Icon(Icons.summarize_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total ${NumberFormat.currency(symbol: "₹").format(split.total)}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  members.isEmpty ? 'Add members to split' : 'Per person ${NumberFormat.currency(symbol: "₹").format(split.perPerson)}',
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${members.length} members', style: Theme.of(context).textTheme.labelMedium),
              Text('$expensesCount expenses', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberBalancesCard extends StatelessWidget {
  final List<String> members;
  final Map<String, double> balances;
  const _MemberBalancesCard({required this.members, required this.balances});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balances', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final m in members)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(m)),
                  _BalancePill(value: balances[m] ?? 0),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final double value;
  const _BalancePill({required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isReceive = value > 0.01;
    final isOwe = value < -0.01;
    final color = isReceive
        ? Colors.greenAccent
        : isOwe
            ? scheme.error
            : scheme.onSurface.withOpacity(0.5);
    final label = isReceive
        ? '+${NumberFormat.currency(symbol: "₹").format(value)}'
        : isOwe
            ? NumberFormat.currency(symbol: "₹").format(value)
            : '₹0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final String name;
  final Future<void> Function() onDelete;
  const _MemberChip({required this.name, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 2, top: 4, bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: Theme.of(context).textTheme.labelMedium),
          IconButton(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Remove member',
            onPressed: () async => onDelete(),
          ),
        ],
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final Settlement s;
  const _SettlementCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(symbol: "₹").format(s.amount);
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            child: const Icon(Icons.swap_horiz),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge,
                children: [
                  TextSpan(text: s.from, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' owes '),
                  TextSpan(text: s.to, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          Text(amount, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _BalanceBarChart extends StatelessWidget {
  final Map<String, double> balances;
  final List<String> members;
  const _BalanceBarChart({required this.balances, required this.members});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vals = [for (final m in members) balances[m] ?? 0];
    final maxAbs = vals.isEmpty ? 1.0 : vals.map((e) => e.abs()).reduce((a, b) => a > b ? a : b);
    final range = maxAbs == 0 ? 1.0 : maxAbs * 1.2;

    return BarChart(
      BarChartData(
        minY: -range,
        maxY: range,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= members.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(members[i], style: Theme.of(context).textTheme.labelSmall, overflow: TextOverflow.ellipsis),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < members.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: balances[members[i]] ?? 0,
                  width: 12,
                  borderRadius: BorderRadius.circular(6),
                  color: (balances[members[i]] ?? 0) >= 0 ? Colors.greenAccent : scheme.error,
                ),
              ],
            )
        ],
      ),
      swapAnimationDuration: const Duration(milliseconds: 650),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }
}

class _TripTimeline extends StatelessWidget {
  final List<TripExpense> expenses;
  final ListSelectionController selection;
  final Future<void> Function(TripExpense expense) deleteExpense;

  const _TripTimeline({
    required this.expenses,
    required this.selection,
    required this.deleteExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < expenses.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (i != expenses.length - 1)
                      Container(
                        height: 64,
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableSwipeTile(
                    itemId: expenses[i].id,
                    selection: selection,
                    dismissKey: ValueKey('trip_exp_${expenses[i].id}'),
                    swipeBackground: deleteSwipeBackground(),
                    confirmSwipeDelete: () async => await showPremiumDeleteDialog(
                          context,
                          title: 'Delete trip expense?',
                          showSuccessSnackBar: false,
                        ),
                    onSwipeConfirmedDelete: () async {
                      await deleteExpense(expenses[i]);
                      if (context.mounted) showItemDeletedSnackbar(context, 'Trip expense deleted');
                    },
                    onTapOpen: null,
                    child: CustomCard(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            child: const Icon(Icons.receipt_long_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${expenses[i].paidBy} paid ${NumberFormat.currency(symbol: "₹").format(expenses[i].amount)}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  expenses[i].note.isEmpty
                                      ? DateFormat('MMM d, h:mm a').format(expenses[i].createdAt)
                                      : expenses[i].note,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(DateFormat('h:mm a').format(expenses[i].createdAt),
                              style: Theme.of(context).textTheme.labelMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Future<void> _showAddMember(BuildContext context, WidgetRef ref, Trip trip) async {
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add member'),
      content: CustomTextField(controller: controller, label: 'Name', textInputAction: TextInputAction.done),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            await ref.read(tripActionsProvider).addMember(trip, controller.text);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

Future<void> _showAddExpenseBottomSheet(BuildContext context, WidgetRef ref, Trip trip) async {
  final amount = TextEditingController();
  final note = TextEditingController();
  String paidBy = trip.members.isEmpty ? '' : trip.members.first;
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add expense', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: paidBy,
                decoration: const InputDecoration(labelText: 'Paid by'),
                items: [for (final m in trip.members) DropdownMenuItem(value: m, child: Text(m))],
                onChanged: (v) => setState(() => paidBy = v ?? paidBy),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                label: 'Amount',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: note,
                label: 'Note',
                hint: 'Optional',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Save',
                  isLoading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          final parsed = double.tryParse(amount.text.trim());
                          if (parsed == null || parsed <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
                            return;
                          }
                          setState(() => saving = true);
                          try {
                            await ref.read(tripActionsProvider).addExpense(
                                  trip: trip,
                                  paidBy: paidBy,
                                  amount: parsed,
                                  note: note.text,
                                );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

