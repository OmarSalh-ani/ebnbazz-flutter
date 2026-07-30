import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter/services.dart';

import '../../models/dashboard_models.dart';

Future<void> showParentContactDialog(
  BuildContext context,
  StudentListItem student,
) {
  final phone = student.fatherPhone.trim();
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        'تواصل مع ولي الأمر',
        style: AppFonts.cairo(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الطالب: ${student.name}', style: AppFonts.cairo()),
          const SizedBox(height: 12),
          SelectableText(
            phone.isEmpty ? 'لا يوجد رقم مسجل' : phone,
            style: AppFonts.cairo(fontSize: 16),
          ),
        ],
      ),
      actions: [
        if (phone.isNotEmpty)
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: phone));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم نسخ الرقم',
                      style: AppFonts.cairo(),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'نسخ الرقم',
              style: AppFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'إغلاق',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
