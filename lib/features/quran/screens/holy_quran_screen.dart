import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';

class HolyQuranScreen extends StatefulWidget {
  const HolyQuranScreen({super.key});

  @override
  State<HolyQuranScreen> createState() => _HolyQuranScreenState();
}

class _HolyQuranScreenState extends State<HolyQuranScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<int> _filteredSurahs = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredSurahs = List.generate(quran.totalSurahCount, (i) => i + 1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = List.generate(quran.totalSurahCount, (i) => i + 1);
      } else {
        _filteredSurahs = List.generate(quran.totalSurahCount, (i) => i + 1).where((surahNumber) {
          final arabicName = quran.getSurahNameArabic(surahNumber);
          final englishName = quran.getSurahName(surahNumber).toLowerCase();
          final number = surahNumber.toString();
          return arabicName.contains(query) || englishName.contains(query.toLowerCase()) || number.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: true,
              backgroundColor: Colors.white,
              elevation: innerBoxIsScrolled ? 2 : 0,
              title: Text(
                'القرآن الكريم',
                style: AppFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'السور'),
                  Tab(text: 'الأجزاء'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSurahList(),
              _buildJuzList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSearchField(),
        const SizedBox(height: 20),
        ..._filteredSurahs.map((surahNumber) => _buildSurahTile(surahNumber)),
        if (_filteredSurahs.isEmpty) _buildNoResults(),
      ],
    );
  }

  Widget _buildJuzList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        final surahsInJuz = quran.getSurahAndVersesFromJuz(juzNumber);
        final firstSurah = surahsInJuz.keys.first;
        
        return _buildGenericTile(
          title: 'الجزء $juzNumber',
          subtitle: 'بداية من سورة ${quran.getSurahNameArabic(firstSurah)}',
          leadingNumber: juzNumber,
          onTap: () {
            context.push(AppRoutes.surahDetailPath(firstSurah));
          },
        );
      },
    );
  }


  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'بحث باسم السورة أو رقمها...',
          hintStyle: AppFonts.cairo(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSurahTile(int surahNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => context.push(AppRoutes.surahDetailPath(surahNumber)),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            surahNumber.toString(),
            style: AppFonts.cairo(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          quran.getSurahNameArabic(surahNumber),
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '${quran.getPlaceOfRevelation(surahNumber) == 'Makkah' ? 'مكية' : 'مدنية'} • ${quran.getVerseCount(surahNumber)} آية',
          style: AppFonts.cairo(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
      ),
    );
  }

  Widget _buildGenericTile({
    required String title,
    required String subtitle,
    required int leadingNumber,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            leadingNumber.toString(),
            style: AppFonts.cairo(
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ),
        title: Text(
          title,
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppFonts.cairo(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'لم يتم العثور على نتائج',
            style: AppFonts.cairo(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
