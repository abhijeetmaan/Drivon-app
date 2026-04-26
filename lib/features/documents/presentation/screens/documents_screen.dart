import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/vehicle_scope.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../shared/dialogs/delete_confirmation.dart' show deleteSwipeBackground, showItemDeletedSnackbar, showPremiumDeleteDialog;
import '../../../../shared/selection/list_selection_controller.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/gradient_fab.dart';
import '../../../../shared/widgets/selectable_swipe_tile.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/staggered_list_entry.dart';
import '../../../../shared/widgets/vehicle_scope_bar.dart';
import '../../../vehicle/presentation/providers/selected_vehicle_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_filter_providers.dart';
import '../../domain/entities/vehicle_document.dart';
import '../providers/document_providers.dart';
import 'add_document_screen.dart';
import 'document_preview_screen.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final ListSelectionController _selection = ListSelectionController();

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  Future<void> _bulkDelete(List<VehicleDocument> docs) async {
    final ids = _selection.selectedIds.toList();
    if (ids.isEmpty) return;
    final n = ids.length;
    final ok = await showPremiumDeleteDialog(
      context,
      title: n == 1 ? 'Delete Document?' : 'Delete $n items?',
      onConfirm: () async {
        for (final id in ids) {
          await ref.read(documentActionsProvider).deleteDocument(id);
        }
      },
      successMessage: n == 1 ? 'Document deleted' : '$n items deleted',
    );
    if (ok && mounted) _selection.clear();
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsProvider);

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
                              final list = ref.read(filteredDocumentsProvider);
                              if (list.isEmpty) return;
                              _bulkDelete(list);
                            },
                    ),
                  ],
                )
              : AppBar(
                  title: const Text('Documents'),
                  actions: [
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddDocumentScreen())),
                      icon: const Icon(Icons.add),
                      tooltip: 'Upload document',
                    ),
                  ],
                ),
          body: docsAsync.when(
            loading: () => SingleChildScrollView(
                  padding: const EdgeInsets.only(top: AppSpacing.s16, bottom: 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(height: 72, borderRadius: BorderRadius.all(Radius.circular(20))),
                      const SizedBox(height: AppSpacing.s16),
                      for (var i = 0; i < 6; i++) ...[
                        const Skeleton(height: 76, borderRadius: BorderRadius.all(Radius.circular(20))),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
            error: (e, _) => Center(child: Text('Failed to load documents: $e')),
            data: (_) {
              final scope = ref.watch(selectedVehicleIdProvider);
              final docs = ref.watch(filteredDocumentsProvider);
              final now = DateTime.now();
              final warnThreshold = now.add(const Duration(days: 30));

              return SingleChildScrollView(
                padding: const EdgeInsets.only(top: AppSpacing.s16, bottom: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                      child: VehicleScopeBar(compact: true),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                      child: CustomCard(
                      prominent: true,
                      child: Text(
                        'We highlight documents expiring in the next 30 days. Long-press to select, swipe right to delete.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    if (docs.isEmpty)
                      EmptyState(
                        icon: Icons.description_outlined,
                        title: 'No documents',
                        message: scope == kAllVehiclesId
                            ? 'Upload insurance/PUC/permits and track expiry dates.'
                            : 'No documents for this vehicle yet. Upload one or switch to All vehicles.',
                        actionLabel: 'Upload',
                        onAction: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddDocumentScreen())),
                      )
                    else
                      ...docs.asMap().entries.map((entry) {
                        final i = entry.key;
                        final d = entry.value;
                        final expired = d.expiryDate.isBefore(now);
                        final expiringSoon = !expired && d.expiryDate.isBefore(warnThreshold);
                        final color = expired
                            ? Theme.of(context).colorScheme.error
                            : expiringSoon
                                ? Colors.orangeAccent
                                : null;
                        final badge = expired
                            ? 'Expired'
                            : expiringSoon
                                ? 'Expiring soon'
                                : 'Valid';

                        final accent = color ?? AppColors.purple;
                        final tile = CustomCard(
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
                                  child: Icon(Icons.description_outlined, color: accent, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        d.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Expires ${DateFormat('MMM d, yyyy').format(d.expiryDate)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: accent.withOpacity(0.14),
                                    ),
                                    child: Text(
                                      badge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withOpacity(0.8)),
                              ],
                            ),
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.s16, right: AppSpacing.s16, bottom: AppSpacing.s8 + 2),
                          child: StaggeredListEntry(
                            index: i,
                            child: SelectableSwipeTile(
                              itemId: d.id,
                              selection: _selection,
                              dismissKey: ValueKey('doc_${d.id}'),
                              swipeBackground: deleteSwipeBackground(),
                              confirmSwipeDelete: () async => await showPremiumDeleteDialog(
                                    context,
                                    title: 'Delete Document?',
                                    showSuccessSnackBar: false,
                                  ),
                              onSwipeConfirmedDelete: () async {
                                await ref.read(documentActionsProvider).deleteDocument(d.id);
                                if (context.mounted) showItemDeletedSnackbar(context, 'Document deleted');
                              },
                              onTapOpen: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => DocumentPreviewScreen(document: d)),
                                );
                              },
                              child: tile,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: _selection.isActive
              ? null
              : GradientExtendedFab(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddDocumentScreen())),
                  icon: Icons.upload_file_rounded,
                  label: 'Upload',
                  tooltip: 'Upload document',
                ),
        );
      },
    );
  }
}
