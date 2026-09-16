import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/primary_switch.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/features/checklist/widgets/custom_ibadah_group.dart';
import 'package:takwa/l10n/app_localizations.dart';

class ManageCustomIbadahScreen extends ConsumerStatefulWidget {
  const ManageCustomIbadahScreen({super.key});

  @override
  ConsumerState<ManageCustomIbadahScreen> createState() =>
      _ManageCustomIbadahScreenState();
}

class _ManageCustomIbadahScreenState
    extends ConsumerState<ManageCustomIbadahScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDialog(BuildContext context, bool isPositive) {
    showDialog(
      context: context,
      builder: (ctx) => _UpsertCustomIbadahDialog(isPositive: isPositive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const CustomLeadingButton(),
        title: Text(l10n.manageIbadahTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.manageIbadahPositiveTab),
            Tab(text: l10n.manageIbadahNegativeTab),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.gold,
        foregroundColor: context.colors.background,
        onPressed: () {
          _showAddDialog(context, _tabController.index == 0);
        },
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          const CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _IbadahList(
                  provider: allPositiveIbadahProvider,
                  isPositive: true,
                ),
                _IbadahList(
                  provider: allNegativeIbadahProvider,
                  isPositive: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IbadahList extends ConsumerWidget {
  final StreamProvider<List<CustomIbadahData>> provider;
  final bool isPositive;

  const _IbadahList({required this.provider, required this.isPositive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(provider);
    final items = asyncData.valueOrNull ?? [];
    final filteredItems = items.where((i) => i.nameAr != 'غضّ البصر').toList();

    return asyncData.when(
      data: (_) {
        if (filteredItems.isEmpty) {
          return Center(
            child: Text(
              l10n.manageIbadahEmpty,
              style: context.typography.bodyLarge.copyWith(
                color: context.colors.textDim,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: AppSpacing.cardPadding.copyWith(bottom: 100),
          itemCount: filteredItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return _IbadahTile(item: item, isPositive: isPositive);
          },
        );
      },
      loading: () =>
          Center(child: TakwaLoadingIndicator(color: context.colors.gold)),
      error: (e, st) => Center(
        child: Text(
          l10n.manageIbadahLoadError,
          style: context.typography.bodyMedium.copyWith(
            color: context.colors.danger,
          ),
        ),
      ),
    );
  }
}

class _IbadahTile extends ConsumerWidget {
  final CustomIbadahData item;
  final bool isPositive;

  const _IbadahTile({required this.item, required this.isPositive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: context.decorations.card,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isPositive
                  ? context.colors.successDim
                  : context.colors.dangerDim,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              isPositive ? Icons.add_task_rounded : Icons.block_rounded,
              color: isPositive
                  ? context.colors.success
                  : context.colors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nameAr,
                  style: context.typography.headingMedium.copyWith(
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPositive
                      ? l10n.manageIbadahPointsEarned(item.points.toString())
                      : l10n.manageIbadahPointsDeducted(item.points.toString()),
                  style: context.typography.caption.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PrimarySwitch(
            value: item.isActive,
            accentColor: isPositive
                ? context.colors.teal
                : context.colors.danger,
            onChanged: (val) async {
              final updatedItem = item.copyWith(isActive: val);
              await ref
                  .read(customIbadahDaoProvider)
                  .updateIbadah(
                    CustomIbadahCompanion(
                      id: drift.Value(item.id),
                      isActive: drift.Value(val),
                    ),
                  );
              await ref.read(syncManagerProvider).syncCustomIbadah(updatedItem);
            },
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: context.colors.teal),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => _UpsertCustomIbadahDialog(
                  isPositive: isPositive,
                  initialItem: item,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.colors.danger),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.manageIbadahDeleteConfirmTitle),
                  content: Text(
                    l10n.manageIbadahDeleteConfirmBody(item.nameAr),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.manageIbadahCancelButton),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.danger,
                      ),
                      child: Text(l10n.manageIbadahDeleteButton),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                try {
                  await ref.read(customIbadahDaoProvider).deleteIbadah(item.id);
                  await ref
                      .read(syncManagerProvider)
                      .deleteCustomIbadah(item.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.manageIbadahDeletedSuccess)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.manageIbadahDeleteFailed(e.toString()),
                        ),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _UpsertCustomIbadahDialog extends ConsumerStatefulWidget {
  final bool isPositive;
  final CustomIbadahData? initialItem;

  const _UpsertCustomIbadahDialog({required this.isPositive, this.initialItem});

  @override
  ConsumerState<_UpsertCustomIbadahDialog> createState() =>
      _UpsertCustomIbadahDialogState();
}

class _UpsertCustomIbadahDialogState
    extends ConsumerState<_UpsertCustomIbadahDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late int _points;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    _name = widget.initialItem?.nameAr ?? '';
    _points = widget.initialItem?.points ?? (widget.isPositive ? 5 : 10);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        _isEditing
            ? (widget.isPositive
                  ? l10n.manageIbadahEditHabitTitle
                  : l10n.manageIbadahEditProhibitionTitle)
            : (widget.isPositive
                  ? l10n.manageIbadahAddPositiveTitle
                  : l10n.manageIbadahAddNegativeTitle),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  labelText: l10n.manageIbadahNameFieldLabel,
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? l10n.manageIbadahRequiredValidation
                    : null,
                onSaved: (val) => _name = val!.trim(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                decoration: InputDecoration(
                  labelText: widget.isPositive
                      ? l10n.manageIbadahPointsEarnedFieldLabel
                      : l10n.manageIbadahPointsDeductedFieldLabel,
                ),
                keyboardType: TextInputType.number,
                initialValue: _points.toString(),
                validator: (val) =>
                    int.tryParse(val ?? '') == null || int.parse(val!) <= 0
                    ? l10n.manageIbadahInvalidNumberValidation
                    : null,
                onSaved: (val) => _points = int.parse(val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.manageIbadahCancelButton),
        ),
        PrimaryButton(
          label: _isEditing
              ? l10n.manageIbadahSaveButton
              : l10n.manageIbadahAddButton,
          onTap: _submit,
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        if (_isEditing) {
          final updated = widget.initialItem!.copyWith(
            nameAr: _name,
            points: _points,
          );
          await ref
              .read(customIbadahDaoProvider)
              .updateIbadah(
                CustomIbadahCompanion(
                  id: drift.Value(updated.id),
                  nameAr: drift.Value(_name),
                  points: drift.Value(_points),
                ),
              );
          await ref.read(syncManagerProvider).syncCustomIbadah(updated);
        } else {
          final id = await ref
              .read(customIbadahDaoProvider)
              .addIbadah(
                CustomIbadahCompanion(
                  nameAr: drift.Value(_name),
                  isPositive: drift.Value(widget.isPositive),
                  points: drift.Value(_points),
                  sortOrder: const drift.Value(0),
                ),
              );

          final newData = CustomIbadahData(
            id: id,
            nameAr: _name,
            isPositive: widget.isPositive,
            points: _points,
            isActive: true,
            sortOrder: 0,
            emoji: '⭐',
          );
          await ref.read(syncManagerProvider).syncCustomIbadah(newData);
        }

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? l10n.manageIbadahUpdatedSuccess
                    : l10n.manageIbadahAddedSuccess,
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.adhkarGenericError(e.toString()),
              ),
            ),
          );
        }
      }
    }
  }
}
