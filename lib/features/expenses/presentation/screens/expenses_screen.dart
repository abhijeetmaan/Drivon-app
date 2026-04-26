import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/expense.dart';
import '../../../../core/constants/vehicle_scope.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/expandable_fab_widget.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/dialogs/delete_confirmation.dart' show deleteSwipeBackground, showItemDeletedSnackbar, showPremiumDeleteDialog;
import '../../../../shared/selection/list_selection_controller.dart';
import '../../../../shared/widgets/selectable_swipe_tile.dart';
import '../../../../shared/widgets/staggered_list_entry.dart';
import '../../../../shared/widgets/premium_expense_vehicle_scope.dart';
import '../../../vehicle/presentation/providers/selected_vehicle_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_filter_providers.dart';
import '../providers/expense_providers.dart';
import 'add_expense_screen.dart';

final _expenseFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'All');

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final ListSelectionController _selection = ListSelectionController();

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  Future<void> _bulkDelete(List<Expense> filtered) async {
    final ids = _selection.selectedIds.toList();
    if (ids.isEmpty) return;
    final n = ids.length;
    final first = n == 1 ? filtered.firstWhere((e) => e.id == ids.first) : null;
    final ok = await showPremiumDeleteDialog(
      context,
      title: n == 1 ? 'Delete ${first!.type} entry?' : 'Delete $n items?',
      onConfirm: () async {
        for (final id in ids) {
          await ref.read(expenseActionsProvider).deleteExpense(id);
        }
      },
      successMessage: n == 1 ? '${first!.type} entry deleted' : '$n items deleted',
    );
    if (ok && mounted) _selection.clear();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final filter = ref.watch(_expenseFilterProvider);

    return ListenableBuilder(
      listenable: _selection,
      builder: (context, _) {
        return AppScaffold(
          appBar: _selection.isActive
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _selection.clear();
                    },
                  ),
                  title: Text(
                    '${_selection.count} selected',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete selected',
                      onPressed: _selection.count == 0
                          ? null
                          : () {
                              final scoped = ref.read(filteredExpensesProvider);
                              final filtered = filter == 'All'
                                  ? scoped
                                  : scoped.where((e) => e.type.toLowerCase() == filter.toLowerCase()).toList();
                              _bulkDelete(filtered);
                            },
                    ),
                  ],
                )
              : AppBar(
                  title: const Text('Expenses'),
                  actions: [
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddExpenseScreen(
                              preferredVehicleId: ref.read(selectedVehicleIdProvider),
                            ),
                          )),
                      icon: const Icon(Icons.add),
                      tooltip: 'Add expense',
                    ),
                  ],
                ),
          body: expensesAsync.when(
        loading: () => SingleChildScrollView(
              padding: const EdgeInsets.only(top: AppSpacing.s16, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(height: 96, borderRadius: BorderRadius.all(Radius.circular(20))),
                  const SizedBox(height: AppSpacing.s16),
                  const Skeleton(height: 40, borderRadius: BorderRadius.all(Radius.circular(12))),
                  const SizedBox(height: AppSpacing.s16),
                  SkeletonLoader.chartBlock(height: 176),
                  const SizedBox(height: AppSpacing.s24),
                  const Skeleton(height: 28, width: 160, borderRadius: BorderRadius.all(Radius.circular(8))),
                  const SizedBox(height: 12),
                  for (var i = 0; i < 5; i++) ...[
                    const Skeleton(height: 76, borderRadius: BorderRadius.all(Radius.circular(20))),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        error: (e, _) => Center(child: Text('Failed to load expenses: $e')),
        data: (_) {
          final scope = ref.watch(selectedVehicleIdProvider);
          final scoped = ref.watch(filteredExpensesProvider);
          final filtered = filter == 'All'
              ? scoped
              : scoped
                  .where((e) => e.type.toLowerCase() == filter.toLowerCase())
                  .toList();

          final total = filtered.fold<double>(0, (sum, e) => sum + e.amount);
          final monthly = _monthlyTotals(scoped);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: AppSpacing.s16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PremiumExpenseVehicleScope(),
                const SizedBox(height: AppSpacing.s12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey<String>('expenses_body_$scope'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  child: CustomCard(
                  prominent: true,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.14),
                        child: const Icon(Icons.payments_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total (${filter.toLowerCase()})',
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 6),
                            Text(
                              NumberFormat.currency(symbol: '₹').format(total),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddExpenseScreen(
                                preferredVehicleId: ref.read(selectedVehicleIdProvider),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Add expense',
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  child: SectionHeader(title: 'Filters'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final f in const [
                      'All',
                      'Fuel',
                      'Service',
                      'Insurance'
                    ])
                      ChoiceChip(
                        label: Text(f),
                        selected: filter == f,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          ref.read(_expenseFilterProvider.notifier).state = f;
                        },
                      ),
                  ],
                ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  child: CustomCard(
                  prominent: true,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly summary',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                          height: 160,
                          child: ClipRect(
                            child: _MonthlyBarChart(monthly: monthly),
                          )),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: AppSpacing.s24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  child: SectionHeader(title: 'Transactions'),
                ),
                if (filtered.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No expenses',
                    message: scoped.isEmpty && scope != kAllVehiclesId
                        ? 'No expenses for this vehicle yet. Add one or switch to All vehicles.'
                        : filter == 'All'
                            ? 'Add fuel/service/insurance to start tracking.'
                            : 'No $filter expenses in this view yet.',
                    actionLabel: 'Add expense',
                    onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => AddExpenseScreen(
                                  preferredVehicleId: ref.read(selectedVehicleIdProvider),
                                ))),
                  )
                else
                  ...filtered.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.s16, right: AppSpacing.s16, bottom: 10),
                      child: StaggeredListEntry(
                        index: e.key,
                        child: SelectableSwipeTile(
                          itemId: e.value.id,
                          selection: _selection,
                          dismissKey: ValueKey('expense_${e.value.id}'),
                          swipeBackground: deleteSwipeBackground(),
                          confirmSwipeDelete: () async => await showPremiumDeleteDialog(
                                context,
                                title: 'Delete ${e.value.type} entry?',
                                showSuccessSnackBar: false,
                              ),
                          onSwipeConfirmedDelete: () async {
                            await ref.read(expenseActionsProvider).deleteExpense(e.value.id);
                            if (context.mounted) {
                              showItemDeletedSnackbar(context, '${e.value.type} entry deleted');
                            }
                          },
                          onTapOpen: null,
                          child: _ExpenseCardContent(expense: e.value),
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
          floatingActionButton: _selection.isActive
              ? null
              : ExpandableFabWidget(
                  actions: [
                    ExpandableFabAction(
                      icon: Icons.local_gas_station_outlined,
                      label: 'Add Fuel',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(
                            initialType: 'Fuel',
                            preferredVehicleId: ref.read(selectedVehicleIdProvider),
                          ),
                        ),
                      ),
                      accent: Colors.orangeAccent,
                    ),
                    ExpandableFabAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Add Expense',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(
                            initialType: 'Service',
                            preferredVehicleId: ref.read(selectedVehicleIdProvider),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ExpenseCardContent extends StatelessWidget {
  final Expense expense;
  const _ExpenseCardContent({required this.expense});

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(symbol: '₹').format(expense.amount);
    final accent = _typeColor(context, expense.type);
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: accent.withOpacity(0.16),
              ),
              child: Icon(_typeIcon(expense.type), color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    expense.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expense.note.isEmpty
                        ? DateFormat('MMM d, yyyy').format(expense.date)
                        : expense.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                amount,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _typeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'fuel':
      return Icons.local_gas_station;
    case 'service':
      return Icons.build_circle_outlined;
    case 'insurance':
      return Icons.verified_user_outlined;
    default:
      return Icons.payments_outlined;
  }
}

Map<DateTime, double> _monthlyTotals(List<Expense> expenses) {
  final map = <DateTime, double>{};
  for (final e in expenses) {
    final dt = DateTime(e.date.year, e.date.month);
    map[dt] = (map[dt] ?? 0) + e.amount;
  }
  final keys = map.keys.toList()..sort();
  // Keep last 6 months for a simple view.
  final last = keys.length <= 6 ? keys : keys.sublist(keys.length - 6);
  return {for (final k in last) k: map[k] ?? 0};
}

class _MonthlyBarChart extends StatelessWidget {
  final Map<DateTime, double> monthly;
  const _MonthlyBarChart({required this.monthly});

  @override
  Widget build(BuildContext context) {
    if (monthly.isEmpty) {
      return Center(
          child: Text('Add some expenses to see the chart',
              style: Theme.of(context).textTheme.bodyMedium));
    }

    final maxY = monthly.values.fold<double>(0, (m, v) => v > m ? v : m);
    final entries = monthly.entries.toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 340;
        final barW = narrow ? 9.0 : 14.0;
        final reservedBottom = narrow ? 24.0 : 28.0;
        return BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: reservedBottom,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MMM').format(entries[i].key),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: narrow ? 9.5 : null),
                      ),
                    );
                  },
                ),
              ),
            ),
            maxY: maxY == 0 ? 1 : maxY * 1.2,
            barGroups: [
              for (int i = 0; i < entries.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entries[i].value,
                      width: barW,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                      color: null,
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.blue, AppColors.purple],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

Color _typeColor(BuildContext context, String type) {
  switch (type.toLowerCase()) {
    case 'fuel':
      return Colors.orangeAccent;
    case 'service':
      return Colors.lightBlueAccent;
    case 'insurance':
      return Colors.lightGreenAccent;
    default:
      return Theme.of(context).colorScheme.primary;
  }
}
