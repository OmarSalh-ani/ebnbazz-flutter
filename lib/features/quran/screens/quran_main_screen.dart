import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/quran_provider.dart';
import '../views/quran_sura_list.dart';

class QuranMainScreen extends ConsumerWidget {
  const QuranMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranData = ref.watch(quranDataProvider);

    return quranData.when(
      data: (data) => SurahListPage(
        jsonData: data['surahs'],
        quarterjsonData: data['quarters'],
      ),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Error loading Quran data: $err'),
        ),
      ),
    );
  }
}
