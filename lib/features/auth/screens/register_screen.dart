import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/core/utils/validators.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import 'package:masged_parent_app/shared/widgets/privacy_policy_link.dart';
import 'package:masged_parent_app/splash/animated_logo.dart';
import 'package:masged_parent_app/splash/floating_particles.dart';
import 'package:masged_parent_app/splash/light_background.dart';
import 'package:masged_parent_app/splash/splash_colors.dart';

import '../../children/providers/students_provider.dart';
import '../models/public_registration_models.dart';
import '../models/registration_student_form_state.dart';
import '../providers/auth_provider.dart';
import '../providers/registration_config_provider.dart';
import '../widgets/auth_country_phone_field.dart';
import '../widgets/auth_premium_text_field.dart';
import '../widgets/registration_students_tabs.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  static const _maxStudents = 5;

  final _formKey = GlobalKey<FormState>();
  final _fatherNameController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fatherNameFocusNode = FocusNode();
  final _phone1FocusNode = FocusNode();
  final _phone2FocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  final List<RegistrationStudentFormState> _students = [
    RegistrationStudentFormState(),
  ];

  String _countryIso1 = 'KW';
  String _countryIso2 = 'KW';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _fatherNameFocused = false;
  bool _phone1Focused = false;
  bool _phone2Focused = false;
  bool _passwordFocused = false;
  bool _confirmPasswordFocused = false;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _orbController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _orbAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _orbAnim = CurvedAnimation(parent: _orbController, curve: Curves.easeInOut);

    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });

    _fatherNameFocusNode.addListener(() {
      setState(() => _fatherNameFocused = _fatherNameFocusNode.hasFocus);
    });
    _phone1FocusNode.addListener(() {
      setState(() => _phone1Focused = _phone1FocusNode.hasFocus);
    });
    _phone2FocusNode.addListener(() {
      setState(() => _phone2Focused = _phone2FocusNode.hasFocus);
    });
    _passwordFocusNode.addListener(() {
      setState(() => _passwordFocused = _passwordFocusNode.hasFocus);
    });
    _confirmPasswordFocusNode.addListener(() {
      setState(
        () => _confirmPasswordFocused = _confirmPasswordFocusNode.hasFocus,
      );
    });
  }

  @override
  void dispose() {
    _fatherNameController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fatherNameFocusNode.dispose();
    _phone1FocusNode.dispose();
    _phone2FocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    for (final s in _students) {
      s.dispose();
    }
    _fadeController.dispose();
    _slideController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  void _addStudent() {
    if (_students.length >= _maxStudents) return;
    setState(() => _students.add(RegistrationStudentFormState()));
  }

  void _removeStudent(int index) {
    if (_students.length <= 1) return;
    setState(() {
      _students[index].dispose();
      _students.removeAt(index);
    });
  }

  Future<void> _submit(PublicRegistrationConfig config) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final labels = config.labels;
    final entries = <RegistrationStudentEntry>[];

    for (final student in _students) {
      final entry = student.toEntry(
        mode: config.mode,
        showBirthdateDiv: labels.showBirthdateDiv,
        showAgeDiv: labels.showAgeDiv,
      );
      if (labels.showBirthdateDiv && entry.birthdate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'يرجى إدخال تاريخ ميلاد صحيح لكل طالب',
              style: AppFonts.cairo(color: Colors.white),
            ),
          ),
        );
        return;
      }
      entries.add(entry);
    }

    ref.read(authProvider.notifier).clearError();

    final phone1 = Validators.digitsOnly(_phone1Controller.text);
    final phone2 = Validators.digitsOnly(_phone2Controller.text);

    final payload = SubmitStudentRegistrationPayload(
      mode: config.mode,
      parentPhoneCountryIso: _countryIso1,
      parentPhone1: phone1,
      parentPhone2: phone2.isEmpty ? null : phone2,
      parentPhone2CountryIso: phone2.isEmpty ? null : _countryIso2,
      fatherName: _fatherNameController.text.trim(),
      password: _passwordController.text,
      students: entries,
    );

    final photos = _students.map((s) => s.pickedPhoto).toList();
    final result = await ref.read(authProvider.notifier).studentRegister(
          payload,
          pendingPhotos: photos,
          studentsApi: ref.read(studentsApiServiceProvider),
        );

    if (!mounted) return;
    if (result != null) {
      ref.invalidate(studentsProvider);
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(registrationConfigProvider);
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: SplashColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _orbAnim,
            builder: (_, __) {
              final pulse = _orbAnim.value;
              return Stack(
                fit: StackFit.expand,
                children: [
                  LightBackground(
                    lightScale: 0.95 + pulse * 0.1,
                    lightOpacity: 0.05 + pulse * 0.03,
                  ),
                  FloatingParticles(progress: pulse),
                ],
              );
            },
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: configAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: SplashColors.gold),
                  ),
                  error: (_, __) => _buildMessageState(
                    'تعذر تحميل إعدادات التسجيل',
                    showLoginLink: true,
                  ),
                  data: (config) {
                    if (!config.registrationEnabled) {
                      return _buildClosedState();
                    }
                    return _buildFormContent(
                      config,
                      authState,
                      isLoading,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(
    PublicRegistrationConfig config,
    AuthState authState,
    bool isLoading,
  ) {
    final labels = config.labels;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader('تسجيل الطلاب'),
                const SizedBox(height: 28),
                _buildFormCard(
                  config: config,
                  labels: labels,
                  authState: authState,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClosedState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
            child: Column(
              children: [
                _buildHeader('التسجيل'),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: SplashColors.gold.withValues(alpha: 0.85),
                        size: 42,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'التسجيل مغلق حالياً',
                        style: AppFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: SplashColors.whiteText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'نعتذر، التسجيل في الأنشطة مغلق حالياً. يرجى المحاولة لاحقاً أو التواصل معنا للاستفسار.',
                        style: AppFonts.cairo(
                          fontSize: 14,
                          height: 1.6,
                          color: SplashColors.whiteText.withValues(alpha: 0.62),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text(
                          'العودة لتسجيل الدخول',
                          style: AppFonts.cairo(
                            color: SplashColors.gold,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: SplashColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageState(String message, {required bool showLoginLink}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: AppFonts.cairo(color: SplashColors.whiteText),
              textAlign: TextAlign.center,
            ),
            if (showLoginLink) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(
                  'العودة لتسجيل الدخول',
                  style: AppFonts.cairo(color: SplashColors.gold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String subtitle) {
    return Column(
      children: [
        Image.asset(
          kSplashLogoAsset,
          width: 168,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SplashColors.gold.withValues(alpha: 0.28)),
          ),
          child: Text(
            subtitle,
            style: AppFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: SplashColors.whiteText.withValues(alpha: 0.82),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({
    required PublicRegistrationConfig config,
    required PublicRegistrationFormLabels labels,
    required AuthState authState,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Form(
          key: _formKey,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('بيانات ولي الأمر'),
                const SizedBox(height: 20),
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: AppFonts.cairo(
                        color: const Color(0xFFFFB4B4),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                AuthPremiumTextField(
                  controller: _fatherNameController,
                  focusNode: _fatherNameFocusNode,
                  isFocused: _fatherNameFocused,
                  label: 'اسم ولي الأمر *',
                  hint: 'أدخل اسم ولي الأمر',
                  icon: Icons.family_restroom_outlined,
                  validator: Validators.validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                AuthCountryPhoneField(
                  label: labels.parentPhone1Label,
                  countryIso: _countryIso1,
                  phoneController: _phone1Controller,
                  focusNode: _phone1FocusNode,
                  isFocused: _phone1Focused,
                  onCountryChanged: (iso) => setState(() => _countryIso1 = iso),
                  validator: (v) =>
                      Validators.validateInternationalPhone(v, _countryIso1),
                ),
                const SizedBox(height: 20),
                if (labels.showPhone2Div) ...[
                  AuthCountryPhoneField(
                    label: 'رقم هاتف ولي الأمر 2 (اختياري)',
                    countryIso: _countryIso2,
                    phoneController: _phone2Controller,
                    focusNode: _phone2FocusNode,
                    isFocused: _phone2Focused,
                    isOptional: true,
                    onCountryChanged: (iso) => setState(() => _countryIso2 = iso),
                    validator: (v) =>
                        Validators.validateInternationalPhone(v, _countryIso2),
                  ),
                  const SizedBox(height: 20),
                ],
                AuthPremiumTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  isFocused: _passwordFocused,
                  label: 'كلمة المرور',
                  hint: 'أدخل كلمة المرور',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: Validators.validatePassword,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                AuthPremiumTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  isFocused: _confirmPasswordFocused,
                  label: 'تأكيد كلمة المرور',
                  hint: 'أعد إدخال كلمة المرور',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleObscure: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  validator: (val) => Validators.validateConfirmPassword(
                    val,
                    _passwordController.text,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('بيانات الطلاب'),
                const SizedBox(height: 8),
                Text(
                  'يمكنك تسجيل أكثر من طالب في نفس الحساب',
                  style: AppFonts.cairo(
                    fontSize: 13,
                    color: SplashColors.whiteText.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 16),
                RegistrationStudentsTabs(
                  students: _students,
                  config: config,
                  maxStudents: _maxStudents,
                  onAddStudent: _addStudent,
                  onRemoveStudent: _removeStudent,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                _buildRegisterButton(isLoading, () => _submit(config)),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'لديك حساب في التطبيق ؟',
                      style: AppFonts.cairo(
                        color: SplashColors.whiteText.withValues(alpha: 0.58),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(
                        'تسجيل الدخول',
                        style: AppFonts.cairo(
                          color: SplashColors.gold,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: SplashColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PrivacyPolicyLink(
                  style: AppFonts.cairo(
                    fontSize: 13,
                    height: 1.6,
                    color: SplashColors.whiteText.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 24,
          decoration: BoxDecoration(
            color: SplashColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SplashColors.whiteText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isLoading, VoidCallback onTap) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: isLoading
              ? SplashColors.gold.withValues(alpha: 0.35)
              : SplashColors.gold,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: SplashColors.gold.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SplashColors.background.withValues(alpha: 0.85),
                    ),
                  ),
                )
              : Text(
                  'إرسال طلب التسجيل',
                  style: AppFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SplashColors.background,
                  ),
                ),
        ),
      ),
    );
  }
}
