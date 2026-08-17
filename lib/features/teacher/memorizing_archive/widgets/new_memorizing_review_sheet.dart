import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';

import 'package:masged_parent_app/core/theme/app_fonts.dart';

import 'package:masged_parent_app/shared/widgets/custom_button.dart';

import 'package:masged_parent_app/teacher_core/network/api_exception.dart';



import '../models/revise_models.dart';

import '../providers/revise_providers.dart';



class NewMemorizingReviewSheet extends ConsumerStatefulWidget {

  const NewMemorizingReviewSheet({

    super.key,

    required this.studentId,

    required this.studentName,

    required this.onSaved,

  });



  final int studentId;

  final String studentName;

  final VoidCallback onSaved;



  static Future<void> show(

    BuildContext context, {

    required int studentId,

    required String studentName,

    required VoidCallback onSaved,

  }) {

    return showModalBottomSheet<void>(

      context: context,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),

      ),

      builder: (context) => Padding(

        padding: EdgeInsets.only(

          bottom: MediaQuery.viewInsetsOf(context).bottom,

        ),

        child: NewMemorizingReviewSheet(

          studentId: studentId,

          studentName: studentName,

          onSaved: onSaved,

        ),

      ),

    );

  }



  @override

  ConsumerState<NewMemorizingReviewSheet> createState() =>

      _NewMemorizingReviewSheetState();

}



class _NewMemorizingReviewSheetState

    extends ConsumerState<NewMemorizingReviewSheet> {

  static const _typeMemorization = 'حفظ';

  static const _typeRevision = 'مراجعة';



  final _surahNameController = TextEditingController();

  final _fromAyahController = TextEditingController();

  final _toAyahController = TextEditingController();



  String _type = _typeMemorization;

  bool _isSaving = false;



  @override

  void dispose() {

    _surahNameController.dispose();

    _fromAyahController.dispose();

    _toAyahController.dispose();

    super.dispose();

  }



  void _showMessage(String text, {bool isError = false}) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(text, style: AppFonts.cairo()),

        backgroundColor: isError ? AppColors.error : null,

      ),

    );

  }



  int? _resolveSurahId(String surahName, List<IdNameOption> surahs) {

    final normalized = surahName.trim();

    if (normalized.isEmpty) return null;



    for (final surah in surahs) {

      if (surah.name.trim() == normalized) {

        return surah.id;

      }

    }

    return null;

  }



  Future<void> _save() async {

    final surahName = _surahNameController.text.trim();

    final fromAyah = int.tryParse(_fromAyahController.text.trim());

    final toAyah = int.tryParse(_toAyahController.text.trim());



    if (surahName.isEmpty ||

        fromAyah == null ||

        toAyah == null ||

        fromAyah <= 0 ||

        toAyah <= 0 ||

        fromAyah > toAyah) {

      _showMessage('يرجى إدخال نطاق آيات صحيح', isError: true);

      return;

    }



    var surahId = 0;

    if (_type == _typeMemorization) {

      try {

        final page =

            await ref.read(revisePageProvider(widget.studentId).future);

        surahId = _resolveSurahId(surahName, page.surahs) ?? 0;

      } catch (_) {

        surahId = 0;

      }

    }



    setState(() => _isSaving = true);

    try {

      final message = await ref.read(reviseRepositoryProvider).create(

            studentId: widget.studentId,

            type: _type,

            surahId: surahId,

            surahName: surahName,

            fromAyah: fromAyah,

            toAyah: toAyah,

          );

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      Navigator.pop(context);

      widget.onSaved();

      messenger.showSnackBar(

        SnackBar(

          content: Text(message, style: AppFonts.cairo()),

        ),

      );

    } on ApiException catch (e) {

      if (mounted) _showMessage(e.message, isError: true);

    } catch (_) {

      if (mounted) _showMessage('تعذر حفظ السجل', isError: true);

    } finally {

      if (mounted) setState(() => _isSaving = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    return SafeArea(

      child: SingleChildScrollView(

        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            Text(

              'حفظ/مراجعة جديد',

              style: AppFonts.cairo(

                fontSize: 18,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 4),

            Text(

              widget.studentName,

              style: AppFonts.cairo(

                fontSize: 13,

                color: AppColors.textSecondary,

              ),

            ),

            const SizedBox(height: 16),

            _buildTypeSelector(),

            const SizedBox(height: 16),

            _buildTextField('السورة', _surahNameController),

            const SizedBox(height: 12),

            Row(

              children: [

                Expanded(

                  child: _buildNumericField('من آية', _fromAyahController),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: _buildNumericField('إلى آية', _toAyahController),

                ),

              ],

            ),

            const SizedBox(height: 24),

            CustomButton(

              text: 'حفظ',

              isLoading: _isSaving,

              onPressed: _isSaving ? null : _save,

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildTypeSelector() {

    return Row(

      children: [_typeMemorization, _typeRevision].map((type) {

        final selected = _type == type;

        return Expanded(

          child: Padding(

            padding: EdgeInsets.only(

              left: type == _typeRevision ? 6 : 0,

              right: type == _typeMemorization ? 6 : 0,

            ),

            child: GestureDetector(

              onTap: () => setState(() => _type = type),

              child: AnimatedContainer(

                duration: const Duration(milliseconds: 200),

                padding: const EdgeInsets.symmetric(vertical: 12),

                decoration: BoxDecoration(

                  color: selected ? AppColors.primary : AppColors.inputFill,

                  borderRadius: BorderRadius.circular(10),

                  border: Border.all(

                    color: selected ? AppColors.primary : AppColors.inputBorder,

                  ),

                ),

                child: Text(

                  type,

                  textAlign: TextAlign.center,

                  style: AppFonts.cairo(

                    fontWeight: FontWeight.bold,

                    color: selected ? Colors.white : AppColors.textSecondary,

                  ),

                ),

              ),

            ),

          ),

        );

      }).toList(),

    );

  }



  Widget _buildTextField(String label, TextEditingController controller) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(

          label,

          style: AppFonts.cairo(

            fontSize: 13,

            fontWeight: FontWeight.w600,

            color: AppColors.textPrimary,

          ),

        ),

        const SizedBox(height: 6),

        TextField(

          controller: controller,

          style: AppFonts.cairo(fontSize: 14),

          textInputAction: TextInputAction.next,

          decoration: _inputDecoration(),

        ),

      ],

    );

  }



  Widget _buildNumericField(String label, TextEditingController controller) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(

          label,

          style: AppFonts.cairo(

            fontSize: 13,

            fontWeight: FontWeight.w600,

            color: AppColors.textPrimary,

          ),

        ),

        const SizedBox(height: 6),

        TextField(

          controller: controller,

          style: AppFonts.cairo(fontSize: 14),

          keyboardType: TextInputType.number,

          inputFormatters: [FilteringTextInputFormatter.digitsOnly],

          textInputAction: TextInputAction.done,

          decoration: _inputDecoration(),

        ),

      ],

    );

  }



  InputDecoration _inputDecoration() {

    return InputDecoration(

      filled: true,

      fillColor: AppColors.inputFill,

      border: OutlineInputBorder(

        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(color: AppColors.inputBorder),

      ),

      enabledBorder: OutlineInputBorder(

        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(color: AppColors.inputBorder),

      ),

      focusedBorder: OutlineInputBorder(

        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(

          color: AppColors.primary,

          width: 1.5,

        ),

      ),

    );

  }

}

