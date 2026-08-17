import 'package:flutter_test/flutter_test.dart';
import 'package:masged_parent_app/features/teacher/memorizing_archive/models/revise_models.dart';

void main() {
  group('buildCreateReviseRequest', () {
    test('builds memorization request with formatted ayah labels', () {
      final request = buildCreateReviseRequest(
        type: 'حفظ',
        surahId: 2,
        surahName: 'البقرة',
        fromAyah: 1,
        toAyah: 5,
      );

      expect(request.memorization, isNotNull);
      expect(request.revision, isNull);
      expect(request.memorization!.surahId, 2);
      expect(request.memorization!.testFrom, 'البقرة - آية 1');
      expect(request.memorization!.testTo, 'البقرة - آية 5');
      expect(request.memorization!.isSaveCompleted, isTrue);
    });

    test('builds revision request without surahId', () {
      final request = buildCreateReviseRequest(
        type: 'مراجعة',
        surahId: 2,
        surahName: 'البقرة',
        fromAyah: 10,
        toAyah: 15,
      );

      expect(request.revision, isNotNull);
      expect(request.memorization, isNull);
      expect(request.revision!.testFrom, 'البقرة - آية 10');
      expect(request.revision!.testTo, 'البقرة - آية 15');
      expect(request.revision!.isRevisionCompleted, isTrue);
    });

    test('throws for invalid type', () {
      expect(
        () => buildCreateReviseRequest(
          type: 'invalid',
          surahId: 1,
          surahName: 'الفاتحة',
          fromAyah: 1,
          toAyah: 2,
        ),
        throwsArgumentError,
      );
    });
  });
}
