import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import 'package:masged_parent_app/shared/widgets/privacy_policy_link.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/permission_onboarding_service.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/utils/validators.dart';
import 'package:masged_parent_app/splash/animated_logo.dart';
import 'package:masged_parent_app/splash/floating_particles.dart';
import 'package:masged_parent_app/splash/light_background.dart';
import 'package:masged_parent_app/splash/splash_colors.dart';

import '../../../app/models/app_role.dart';
import '../../../app/providers/app_role_provider.dart';
import '../../teacher/auth/providers/auth_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/registration_config_provider.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_premium_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  AppRole _role = AppRole.parent;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _phoneFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _canUseBiometrics = false;
  bool _hasSavedCredentials = false;
  BiometricType? _primaryBiometricType;

  final LocalAuthentication _localAuth = LocalAuthentication();

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _orbController;

  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _orbAnim;

  bool get _isTeacher => _role == AppRole.teacher;

  @override
  void initState() {
    super.initState();

    final savedRole = ref.read(appRoleProvider);
    if (savedRole == AppRole.parent || savedRole == AppRole.teacher) {
      _role = savedRole!;
    }

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

    _phoneFocusNode.addListener(() {
      setState(() => _phoneFocused = _phoneFocusNode.hasFocus);
    });
    _emailFocusNode.addListener(() {
      setState(() => _emailFocused = _emailFocusNode.hasFocus);
    });
    _passwordFocusNode.addListener(() {
      setState(() => _passwordFocused = _passwordFocusNode.hasFocus);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isTeacher) {
        await _loadSavedCredentials();
        await _checkBiometricAvailability();
      }
    });
  }

  Future<void> _selectRole(AppRole role) async {
    if (_role == role) return;
    FocusScope.of(context).unfocus();
    _formKey.currentState?.reset();
    setState(() {
      _role = role;
      _obscurePassword = true;
    });
    await ref.read(appRoleProvider.notifier).selectRole(role);
    if (role == AppRole.teacher) {
      await _loadSavedCredentials();
      await _checkBiometricAvailability();
    }
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await ref.read(authRepositoryProvider).getSavedCredentials();
    if (!mounted) return;
    if (saved.email != null && saved.email!.isNotEmpty) {
      _emailController.text = saved.email!;
    }
    if (saved.password != null && saved.password!.isNotEmpty) {
      _passwordController.text = saved.password!;
    }
    final hasCreds = (saved.email?.isNotEmpty ?? false) &&
        (saved.password?.isNotEmpty ?? false);
    if (hasCreds != _hasSavedCredentials) {
      setState(() => _hasSavedCredentials = hasCreds);
    }
  }

  Future<void> _checkBiometricAvailability() async {
    if (kIsWeb || !_isTeacher) return;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final biometrics = await _localAuth.getAvailableBiometrics();
      final saved = await ref.read(authRepositoryProvider).getSavedCredentials();
      final hasCreds = (saved.email?.isNotEmpty ?? false) &&
          (saved.password?.isNotEmpty ?? false);

      BiometricType? primaryType;
      if (biometrics.contains(BiometricType.face)) {
        primaryType = BiometricType.face;
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        primaryType = BiometricType.fingerprint;
      } else if (biometrics.contains(BiometricType.strong)) {
        primaryType = BiometricType.strong;
      } else if (biometrics.isNotEmpty) {
        primaryType = biometrics.first;
      }

      if (!mounted) return;
      setState(() {
        _canUseBiometrics =
            (canCheck || isSupported) && biometrics.isNotEmpty;
        _hasSavedCredentials = hasCreds;
        _primaryBiometricType = primaryType;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _canUseBiometrics = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isTeacher) {
      await _performTeacherLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      await _performParentLogin();
    }
  }

  Future<void> _navigateAfterLogin({required bool isTeacher}) async {
    await PermissionOnboardingService.markCompleted();
    if (!mounted) return;
    context.go(
      isTeacher ? AppRoutes.teacherDashboard : AppRoutes.home,
    );
  }

  Future<void> _performParentLogin() async {
    await ref.read(appRoleProvider.notifier).selectRole(AppRole.parent);
    ref.read(authProvider.notifier).clearError();
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authProvider.notifier).login(
            _phoneController.text.trim(),
            _passwordController.text,
          );
      if (!mounted) return;
      if (success) await _navigateAfterLogin(isTeacher: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (!_canUseBiometrics || !_hasSavedCredentials || _isLoading) return;

    FocusScope.of(context).unfocus();
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'أدخل بصمة الإصبع أو Face ID لتسجيل الدخول',
        persistAcrossBackgrounding: true,
      );
      if (!didAuthenticate || !mounted) return;

      final saved = await ref.read(authRepositoryProvider).getSavedCredentials();
      if (saved.email == null ||
          saved.email!.isEmpty ||
          saved.password == null ||
          saved.password!.isEmpty) {
        if (mounted) {
          _showError('لا توجد بيانات محفوظة. سجّل الدخول بالبريد أولاً.');
        }
        return;
      }

      await _performTeacherLogin(
        email: saved.email!,
        password: saved.password!,
      );
    } on LocalAuthException catch (e) {
      if (!mounted) return;
      if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled) {
        return;
      }
      _showError(_biometricErrorMessage(e.code));
    } catch (_) {
      if (mounted) _showError('تعذّر التحقق بالبصمة. حاول مرة أخرى.');
    }
  }

  String _biometricErrorMessage(LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return 'لم يتم إعداد البصمة أو Face ID على هذا الجهاز.';
      case LocalAuthExceptionCode.biometricLockout:
      case LocalAuthExceptionCode.temporaryLockout:
        return 'تم قفل البصمة مؤقتاً. استخدم كلمة المرور أو حاول لاحقاً.';
      default:
        return 'تعذّر التحقق بالبصمة. حاول مرة أخرى.';
    }
  }

  Future<void> _performTeacherLogin({
    required String email,
    required String password,
  }) async {
    await ref.read(appRoleProvider.notifier).selectRole(AppRole.teacher);
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: email,
            password: password,
          );
      if (mounted) await _navigateAfterLogin(isTeacher: true);
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) {
        final message = e is ApiException
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
        _showError(message.isNotEmpty ? message : 'حدث خطأ غير متوقع');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppFonts.cairo(color: Colors.white, fontSize: 14),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'نسيت كلمة المرور؟',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'لم يتوفر بعد استرداد كلمة المرور آلياً. يرجى التواصل مع إدارة المسجد لإعادة تعيين كلمة المرور أو التسجيل لأول مرة إذا كانت بياناتك مسجَّلة ولكن لم يتم تفعيل الحساب.',
          style: AppFonts.cairo(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'حسناً',
              style: AppFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _browseAsGuest() async {
    final uri = Uri.parse('https://www.ebnbazz.com');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = _isTeacher ? _isLoading : authState.isLoading || _isLoading;

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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 44,
                        ),
                        child: Column(
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 28),
                            _buildFormCard(authState, isLoading),
                          ],
                        ),
                      ),
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

  Widget _buildHeader() {
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
            border: Border.all(
              color: SplashColors.gold.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            _isTeacher
                ? 'لوحة تحكم المعلمين'
                : 'متابعة الأبناء والحضور والتواصل',
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

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleTab(
              label: 'ولي أمر',
              englishLabel: 'Parent',
              icon: Icons.family_restroom_rounded,
              selected: _role == AppRole.parent,
              onTap: () => _selectRole(AppRole.parent),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _RoleTab(
              label: 'معلم',
              englishLabel: 'Teacher',
              icon: Icons.school_rounded,
              selected: _role == AppRole.teacher,
              onTap: () => _selectRole(AppRole.teacher),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(AuthState authState, bool isLoading) {
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
                Row(
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
                    Text(
                      'تسجيل الدخول',
                      style: AppFonts.cairo(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: SplashColors.whiteText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Text(
                    _isTeacher
                        ? 'Teacher login — use email and password'
                        : 'اختر طريقة الدخول وأدخل بياناتك',
                    style: AppFonts.cairo(
                      fontSize: 13,
                      color: SplashColors.whiteText.withValues(alpha: 0.58),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildRoleSelector(),
                const SizedBox(height: 24),
                if (!_isTeacher && authState.errorMessage != null) ...[
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
                  if (_isTeacher)
                    AuthPremiumTextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      isFocused: _emailFocused,
                      label: 'البريد الإلكتروني',
                      hint: 'example@school.com',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                    )
                  else
                    AuthPhoneField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      isFocused: _phoneFocused,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                    ),
                  const SizedBox(height: 20),
                  AuthPremiumTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    isFocused: _passwordFocused,
                    label: 'كلمة المرور',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    validator: Validators.validatePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  if (!_isTeacher) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          'نسيت كلمة المرور ؟',
                          style: AppFonts.cairo(
                            color: SplashColors.whiteText.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildLoginButton(isLoading),
                  const SizedBox(height: 12),
                  _buildGuestBrowseButton(),
                  if (_isTeacher &&
                      _canUseBiometrics &&
                      _hasSavedCredentials) ...[
                    const SizedBox(height: 20),
                    _buildBiometricLoginSection(isLoading),
                  ],
                  if (!_isTeacher) ...[
                    Builder(
                      builder: (context) {
                        final registrationConfig =
                            ref.watch(registrationConfigProvider);
                        final showRegister = registrationConfig.maybeWhen(
                          data: (config) => config.registrationEnabled,
                          orElse: () => false,
                        );
                        if (!showRegister) return const SizedBox.shrink();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ليس لديك حساب في التطبيق ؟',
                              style: AppFonts.cairo(
                                color: SplashColors.whiteText.withValues(alpha: 0.58),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await ref
                                    .read(appRoleProvider.notifier)
                                    .selectRole(AppRole.parent);
                                if (!context.mounted) return;
                                context.push(AppRoutes.register);
                              },
                              child: Text(
                                'تسجيل جديد',
                                style: AppFonts.cairo(
                                  color: SplashColors.gold,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: SplashColors.gold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
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

  String get _biometricLabel {
    if (_primaryBiometricType == BiometricType.face) {
      return 'تسجيل الدخول بـ Face ID';
    }
    return 'تسجيل الدخول بالبصمة';
  }

  IconData get _biometricIcon {
    if (_primaryBiometricType == BiometricType.face) {
      return Icons.face_rounded;
    }
    return Icons.fingerprint_rounded;
  }

  Widget _buildBiometricLoginSection(bool isLoading) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.12),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'أو',
                style: AppFonts.cairo(
                  fontSize: 13,
                  color: SplashColors.whiteText.withValues(alpha: 0.45),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.12),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: isLoading ? null : _loginWithBiometrics,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: SplashColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SplashColors.gold.withValues(alpha: 0.42),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_biometricIcon, color: SplashColors.gold, size: 26),
                const SizedBox(width: 10),
                Text(
                  _biometricLabel,
                  style: AppFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SplashColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _login,
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'تسجيل الدخول',
                      style: AppFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: SplashColors.background,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: SplashColors.background.withValues(alpha: 0.9),
                      size: 16,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGuestBrowseButton() {
    return GestureDetector(
      onTap: _browseAsGuest,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore_rounded,
              color: SplashColors.whiteText.withValues(alpha: 0.75),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'تصفح كزائر',
              style: AppFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: SplashColors.whiteText.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.englishLabel,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String englishLabel;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? SplashColors.gold
        : SplashColors.whiteText.withValues(alpha: 0.45);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? SplashColors.gold.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: SplashColors.gold.withValues(alpha: 0.45))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                englishLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: selected ? 0.9 : 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
