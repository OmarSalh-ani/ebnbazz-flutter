import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/platform/student_photo_picker.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/splash/splash_colors.dart';

class AuthStudentPhotoPicker extends StatefulWidget {
  const AuthStudentPhotoPicker({
    super.key,
    required this.photo,
    required this.onPhotoChanged,
  });

  final PickedStudentPhoto? photo;
  final ValueChanged<PickedStudentPhoto?> onPhotoChanged;

  @override
  State<AuthStudentPhotoPicker> createState() => _AuthStudentPhotoPickerState();
}

class _AuthStudentPhotoPickerState extends State<AuthStudentPhotoPicker> {
  PickedStudentPhoto? _previewPhoto;

  @override
  void didUpdateWidget(AuthStudentPhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previewPhoto = widget.photo;
  }

  @override
  void initState() {
    super.initState();
    _previewPhoto = widget.photo;
  }

  Future<void> _pick(StudentPhotoSource source) async {
    final picked = await StudentPhotoPicker.pick(source);
    if (!mounted || picked == null) return;

    setState(() => _previewPhoto = picked);
    widget.onPhotoChanged(picked);
  }

  void _clearPhoto() {
    setState(() => _previewPhoto = null);
    widget.onPhotoChanged(null);
  }

  void _openPreview(PickedStudentPhoto photo) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.memory(
                  photo.bytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = _previewPhoto ?? widget.photo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'صورة الطالب (اختياري)',
          style: AppFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: SplashColors.whiteText.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _PhotoThumbnail(
              photo: photo,
              onTap: photo != null ? () => _openPreview(photo) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PhotoActionButton(
                    label: 'من المعرض',
                    icon: Icons.photo_library_outlined,
                    onTap: () => _pick(StudentPhotoSource.gallery),
                  ),
                  const SizedBox(height: 8),
                  _PhotoActionButton(
                    label: 'من الكاميرا',
                    icon: Icons.camera_alt_outlined,
                    onTap: () => _pick(StudentPhotoSource.camera),
                  ),
                ],
              ),
            ),
            if (photo != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearPhoto,
                tooltip: 'إزالة الصورة',
                icon: Icon(
                  Icons.close_rounded,
                  color: SplashColors.whiteText.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
        if (photo != null) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _openPreview(photo),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    photo.bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: SplashColors.whiteText.withValues(alpha: 0.35),
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'معاينة الصورة',
                            style: AppFonts.cairo(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            photo.fileName,
            style: AppFonts.cairo(
              fontSize: 12,
              color: SplashColors.whiteText.withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.photo,
    this.onTap,
  });

  final PickedStudentPhoto? photo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: photo != null
                ? SplashColors.gold.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: photo != null
            ? Image.memory(
                photo!.bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image_outlined,
                  color: SplashColors.whiteText.withValues(alpha: 0.35),
                  size: 32,
                ),
              )
            : Icon(
                Icons.person_outline_rounded,
                color: SplashColors.whiteText.withValues(alpha: 0.35),
                size: 32,
              ),
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: SplashColors.gold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.cairo(
                  fontSize: 13,
                  color: SplashColors.whiteText.withValues(alpha: 0.82),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
