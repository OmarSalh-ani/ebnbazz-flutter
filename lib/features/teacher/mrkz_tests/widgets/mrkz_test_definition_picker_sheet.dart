import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../models/mrkz_test_models.dart';

Future<MrkzTestDefinitionOption?> showMrkzTestDefinitionPickerSheet({
  required BuildContext context,
  required List<MrkzTestDefinitionOption> definitions,
  MrkzTestDefinitionOption? selected,
}) {
  return showModalBottomSheet<MrkzTestDefinitionOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _MrkzTestDefinitionPickerSheet(
      definitions: definitions,
      selected: selected,
    ),
  );
}

class _MrkzTestDefinitionPickerSheet extends StatefulWidget {
  const _MrkzTestDefinitionPickerSheet({
    required this.definitions,
    this.selected,
  });

  final List<MrkzTestDefinitionOption> definitions;
  final MrkzTestDefinitionOption? selected;

  @override
  State<_MrkzTestDefinitionPickerSheet> createState() =>
      _MrkzTestDefinitionPickerSheetState();
}

class _MrkzTestDefinitionPickerSheetState
    extends State<_MrkzTestDefinitionPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MrkzTestDefinitionOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.definitions;
    return widget.definitions
        .where((item) => item.mtnName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.75;
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'اختر المتن',
                style: AppFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ابحث عن المتن',
                  hintStyle: AppFonts.cairo(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search, color: AppColors.mrkzPrimary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _query.isNotEmpty ? 'لا توجد نتائج' : 'لا توجد متون متاحة',
                        style: AppFonts.cairo(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = widget.selected?.id == item.id;
                        return Material(
                          color: isSelected
                              ? AppColors.mrkzPrimary.withValues(alpha: 0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(item),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.mrkzPrimary.withValues(alpha: 0.35)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.mtnName,
                                          style: AppFonts.cairo(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'الدرجة: ${_formatScore(item.totalScore)} • وزن الخطأ: ${_formatScore(item.errorWeight)}',
                                          style: AppFonts.cairo(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.mrkzPrimary,
                                    )
                                  else
                                    const Icon(
                                      Icons.chevron_left,
                                      color: AppColors.textHint,
                                    ),
                                ],
                              ),
                            ),
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

  String _formatScore(double score) {
    if (score == score.roundToDouble()) {
      return score.round().toString();
    }
    return score.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}
