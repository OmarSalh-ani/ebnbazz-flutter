import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/services/permission_onboarding_service.dart';
import '../../../core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();

  void _verify() async {
    if (_otpController.text.length == 6) {
      final success = await ref
          .read(authProvider.notifier)
          .verifyOtp(_otpController.text, widget.phone);
      if (success && mounted) {
        final onboardingComplete =
            await PermissionOnboardingService.hasCompleted();
        if (!mounted) return;
        context.go(
          onboardingComplete ? AppRoutes.home : AppRoutes.permissionAsk,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التحقق من رقم الجوال')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'أدخل رمز التحقق المرسل إلى',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.phone,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 40),
            Directionality(
              textDirection: TextDirection.ltr,
              child: PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 50,
                  fieldWidth: 45,
                  activeFillColor: AppColors.surface,
                  inactiveFillColor: AppColors.inputFill,
                  selectedFillColor: AppColors.surface,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.inputBorder,
                  selectedColor: AppColors.primary,
                ),
                enableActiveFill: true,
                onChanged: (_) => setState(() {}),
                onCompleted: (value) => _verify(),
              ),
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  authState.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 40),
            CustomButton(
              text: 'تأكيد',
              onPressed: _otpController.text.length == 6 ? _verify : null,
              isLoading: authState.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
