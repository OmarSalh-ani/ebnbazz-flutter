import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
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
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    final url = widget.release.downloadLink.trim();
    if (url.isEmpty) return;
    _pdfController = PdfControllerPinch(document: _openPdf(url));
  }

  Future<PdfDocument> _openPdf(String url) async {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('empty pdf');
    }
    return PdfDocument.openData(
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

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
            : PdfViewPinch(
                controller: _pdfController!,
                builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                  documentLoaderBuilder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  pageLoaderBuilder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorBuilder: (_, __) => Center(
                    child: Text(
                      'تعذر فتح الملف',
                      style: AppFonts.cairo(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
