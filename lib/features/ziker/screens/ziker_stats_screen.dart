import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import 'ziker_screen.dart';

class ZikerStatsScreen extends StatefulWidget {
  const ZikerStatsScreen({super.key, this.useNavigatorPush = false});

  /// Teacher dashboard opens this screen via [Navigator.push]; detail pages
  /// must use the same stack instead of go_router.
  final bool useNavigatorPush;

  @override
  State<ZikerStatsScreen> createState() => _ZikerStatsScreenState();
}

class _ZikerStatsScreenState extends State<ZikerStatsScreen> {
  static const String _customAdhkarKey = 'custom_adhkar';
  static const String _hiddenDefaultsKey = 'hidden_default_adhkar';

  final List<String> _defaultAdhkar = [
    'سبحان الله',
    'الحمد لله',
    'لا إله إلا الله',
    'الله أكبر',
    'أستغفر الله',
    'لا حول ولا قوة إلا بالله',
    'الصلاة على النبي',
    'الصلاة على النبي بالصيغة الابراهيمية',
  ];
  List<String> _adhkar = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList(_customAdhkarKey) ?? [];
    final hiddenDefaults = prefs.getStringList(_hiddenDefaultsKey) ?? [];

    _adhkar = [
      ..._defaultAdhkar.where((ziker) => !hiddenDefaults.contains(ziker)),
      ...custom,
    ];

    final Map<String, int> stats = {};
    for (String ziker in _adhkar) {
      stats[ziker] = prefs.getInt('ziker_counter_$ziker') ?? 0;
    }
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  bool _isDuplicateName(String name, {String? exclude}) {
    return _adhkar.any((ziker) => ziker == name && ziker != exclude);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppFonts.cairo()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveAdhkarName(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    if (_isDuplicateName(trimmed, exclude: oldName)) {
      _showMessage('هذا الذكر موجود بالفعل');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('ziker_counter_$oldName') ?? 0;

    if (_defaultAdhkar.contains(oldName)) {
      final hidden = prefs.getStringList(_hiddenDefaultsKey) ?? [];
      if (!hidden.contains(oldName)) {
        hidden.add(oldName);
        await prefs.setStringList(_hiddenDefaultsKey, hidden);
      }

      final custom = prefs.getStringList(_customAdhkarKey) ?? [];
      custom.add(trimmed);
      await prefs.setStringList(_customAdhkarKey, custom);
    } else {
      final custom = prefs.getStringList(_customAdhkarKey) ?? [];
      final index = custom.indexOf(oldName);
      if (index >= 0) {
        custom[index] = trimmed;
        await prefs.setStringList(_customAdhkarKey, custom);
      }
    }

    await prefs.remove('ziker_counter_$oldName');
    if (count > 0) {
      await prefs.setInt('ziker_counter_$trimmed', count);
    }

    if (mounted) {
      Navigator.pop(context);
      await _loadAllStats();
    }
  }

  Future<void> _deleteAdhkar(String ziker) async {
    final prefs = await SharedPreferences.getInstance();

    if (_defaultAdhkar.contains(ziker)) {
      final hidden = prefs.getStringList(_hiddenDefaultsKey) ?? [];
      if (!hidden.contains(ziker)) {
        hidden.add(ziker);
        await prefs.setStringList(_hiddenDefaultsKey, hidden);
      }
    } else {
      final custom = prefs.getStringList(_customAdhkarKey) ?? [];
      custom.remove(ziker);
      await prefs.setStringList(_customAdhkarKey, custom);
    }

    await prefs.remove('ziker_counter_$ziker');
    await _loadAllStats();
  }

  void _showAdhkarDialog({String? existingName}) {
    final isEditing = existingName != null;
    final controller = TextEditingController(text: existingName ?? '');

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            isEditing ? 'تعديل الذكر' : 'إضافة ذكر جديد',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'أدخل نص الذكر هنا...',
              hintStyle: AppFonts.cairo(fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            style: AppFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: AppFonts.cairo(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                if (isEditing) {
                  await _saveAdhkarName(existingName, text);
                } else if (_isDuplicateName(text)) {
                  _showMessage('هذا الذكر موجود بالفعل');
                } else {
                  final prefs = await SharedPreferences.getInstance();
                  final custom = prefs.getStringList(_customAdhkarKey) ?? [];
                  custom.add(text);
                  await prefs.setStringList(_customAdhkarKey, custom);
                  if (context.mounted) {
                    Navigator.pop(context);
                    await _loadAllStats();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isEditing ? 'حفظ' : 'إضافة',
                style: AppFonts.cairo(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String ziker) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('حذف الذكر', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text(
            'هل تريد حذف "$ziker"؟ سيتم حذف إحصائياته أيضاً.',
            style: AppFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: AppFonts.cairo(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAdhkar(ziker);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('حذف', style: AppFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomDialog() => _showAdhkarDialog();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'التسبيح',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _adhkar.length,
                itemBuilder: (context, index) {
                  final ziker = _adhkar[index];
                  final count = _stats[ziker] ?? 0;
                  return GestureDetector(
                    onTap: () async {
                      if (widget.useNavigatorPush) {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ZikerScreen(zikerName: ziker),
                          ),
                        );
                      } else {
                        await context.push(AppRoutes.zikerPath(ziker));
                      }
                      _loadAllStats();
                    },
                    child: _buildStatCard(ziker, count, index),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddCustomDialog,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatCard(String name, int count, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vibration_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'إجمالي عدد التسبيحات',
                  style: AppFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count.toString(),
                style: AppFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'تسبيحة',
                style: AppFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            onSelected: (value) {
              if (value == 'edit') {
                _showAdhkarDialog(existingName: name);
              } else if (value == 'delete') {
                _showDeleteConfirmation(name);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text('تعديل', style: AppFonts.cairo()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    Text('حذف', style: AppFonts.cairo(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }
}
