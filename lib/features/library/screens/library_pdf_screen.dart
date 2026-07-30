import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../models/center_release_model.dart';

class LibraryPdfScreen extends StatefulWidget {
  const LibraryPdfScreen({super.key, required this.release});

  final CenterReleaseModel release;

  @override
  State<LibraryPdfScreen> createState() => _LibraryPdfScreenState();
}

class _LibraryPdfScreenState extends State<LibraryPdfScreen> {
  bool _downloading = false;

  Future<void> _downloadAndShare() async {
    final link = widget.release.downloadLink.trim();
    if (link.isEmpty) {
      _showMessage('رابط التحميل غير متوفر');
      return;
    }

    setState(() => _downloading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final libraryDir = Directory('${dir.path}/library');
      if (!await libraryDir.exists()) {
        await libraryDir.create(recursive: true);
      }

      final safeName = widget.release.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final fileName =
          '${safeName.isEmpty ? 'release_${widget.release.id}' : safeName}.pdf';
      final filePath = '${libraryDir.path}/$fileName';

      await Dio().download(link, filePath);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/pdf')],
          subject: widget.release.title,
          text: widget.release.title,
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage('تعذر تحميل الملف');
      }
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: AppFonts.cairo())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.release.downloadLink.trim();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.release.title,
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          actions: [
            if (_downloading)
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'تحميل',
                onPressed: _downloadAndShare,
                icon: const Icon(Icons.download_rounded),
              ),
          ],
        ),
        body: url.isEmpty
            ? Center(
                child: Text(
                  'رابط الملف غير متوفر',
                  style: AppFonts.cairo(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              )
            : PdfViewer.uri(Uri.parse(url)),
      ),
    );
  }
}
