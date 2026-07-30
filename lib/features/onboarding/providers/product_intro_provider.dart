import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/product_intro_service.dart';

final productIntroProvider =
    StateNotifierProvider<ProductIntroNotifier, AsyncValue<bool>>((ref) {
  return ProductIntroNotifier();
});

class ProductIntroNotifier extends StateNotifier<AsyncValue<bool>> {
  ProductIntroNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await ProductIntroService.hasCompleted());
  }

  Future<void> markCompleted() async {
    await ProductIntroService.markCompleted();
    state = const AsyncValue.data(true);
  }

  Future<void> reload() async {
    await _load();
  }
}
