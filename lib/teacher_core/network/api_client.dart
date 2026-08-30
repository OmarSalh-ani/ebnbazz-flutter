import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:masged_parent_app/core/config/unified_api_config.dart';

import '../config/api_config.dart';
import '../storage/auth_storage.dart';
import 'api_exception.dart';
import 'global_response.dart';

class DownloadedBytes {
  const DownloadedBytes({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

class TeacherApiClient {
  TeacherApiClient(this._authStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: UnifiedApiConfig.teacherBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  final AuthStorage _authStorage;
  late final Dio _dio;

  Dio get dio => _dio;

  String _resolvePath(String path) => UnifiedApiConfig.teacherPath(path);

  Future<T> post<T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(dynamic json) parseData,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _resolvePath(path),
        data: body,
      );
      return _parseEnvelope(response.data, parseData);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) parseData,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _resolvePath(path),
        queryParameters: queryParameters,
      );
      return _parseEnvelope(response.data, parseData);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// GET that returns raw bytes (e.g. a PDF certificate).
  Future<DownloadedBytes> getBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
    String accept = 'application/pdf',
    required String fallbackFileName,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        _resolvePath(path),
        queryParameters: queryParameters,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': accept},
        ),
      );
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw ApiException(message: 'استجابة فارغة من الخادم');
      }

      final bytes = Uint8List.fromList(data);
      if (!_isPdfBytes(bytes)) {
        throw ApiException(message: 'استجابة الخادم ليست ملف PDF صالح');
      }

      final fileName = _fileNameFromContentDisposition(
            response.headers.value('content-disposition'),
          ) ??
          fallbackFileName;

      return DownloadedBytes(
        bytes: bytes,
        fileName: fileName,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> postVoid(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _resolvePath(path),
        data: body,
      );
      _ensureSuccess(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<String> deleteCommand(String path) async {
    try {
      final response =
          await _dio.delete<Map<String, dynamic>>(_resolvePath(path));
      final json = response.data;
      _ensureSuccess(json);

      final data = json?['data'];
      if (data is Map<String, dynamic>) {
        final dataMessage = data['message'] as String?;
        if (dataMessage != null && dataMessage.isNotEmpty) {
          return dataMessage;
        }
      }

      final envelopeMessage = json?['message'] as String?;
      if (envelopeMessage != null && envelopeMessage.isNotEmpty) {
        return envelopeMessage;
      }

      return 'تمت العملية بنجاح';
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(dynamic json) parseData,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        _resolvePath(path),
        data: body,
      );
      return _parseEnvelope(response.data, parseData);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<String> putCommand(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        _resolvePath(path),
        data: body,
      );
      final json = response.data;
      _ensureSuccess(json);

      final data = json?['data'];
      if (data is Map<String, dynamic>) {
        final dataMessage = data['message'] as String?;
        if (dataMessage != null && dataMessage.isNotEmpty) {
          return dataMessage;
        }
      }

      final envelopeMessage = json?['message'] as String?;
      if (envelopeMessage != null && envelopeMessage.isNotEmpty) {
        return envelopeMessage;
      }

      return 'تمت العملية بنجاح';
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST that returns a user-facing message from [data.message] or [message].
  Future<String> postCommand(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _resolvePath(path),
        data: body,
      );
      final json = response.data;
      _ensureSuccess(json);

      final data = json?['data'];
      if (data is Map<String, dynamic>) {
        final dataMessage = data['message'] as String?;
        if (dataMessage != null && dataMessage.isNotEmpty) {
          return dataMessage;
        }
      }

      final envelopeMessage = json?['message'] as String?;
      if (envelopeMessage != null && envelopeMessage.isNotEmpty) {
        return envelopeMessage;
      }

      return 'تمت العملية بنجاح';
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  void _ensureSuccess(Map<String, dynamic>? json) {
    if (json == null) {
      throw ApiException(message: 'استجابة فارغة من الخادم');
    }

    final envelope = GlobalResponse<dynamic>.fromJson(json);
    if (!envelope.success) {
      throw ApiException(
        message: envelope.message.isNotEmpty
            ? envelope.message
            : 'حدث خطأ أثناء تنفيذ الطلب',
        statusCode: envelope.statusCode,
      );
    }
  }

  T _parseEnvelope<T>(
    Map<String, dynamic>? json,
    T Function(dynamic json) parseData,
  ) {
    if (json == null) {
      throw ApiException(message: 'استجابة فارغة من الخادم');
    }

    final envelope = GlobalResponse<T>.fromJson(
      json,
      fromJsonT: parseData,
    );

    if (!envelope.success) {
      throw ApiException(
        message: envelope.message.isNotEmpty
            ? envelope.message
            : 'حدث خطأ أثناء تنفيذ الطلب',
        statusCode: envelope.statusCode,
      );
    }

    if (envelope.data == null) {
      throw ApiException(message: 'لا توجد بيانات في الاستجابة');
    }

    return envelope.data as T;
  }

  ApiException _mapDioError(DioException error) {
    final message = _messageFromErrorBody(error.response?.data);
    if (message != null && message.isNotEmpty) {
      return ApiException(
        message: message,
        statusCode: error.response?.statusCode,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException(message: 'انتهت مهلة الاتصال بالخادم');
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'تعذر الاتصال بالخادم. تحقق من عنوان API والشبكة',
        );
      default:
        return ApiException(
          message: error.message ?? 'حدث خطأ في الاتصال',
          statusCode: error.response?.statusCode,
        );
    }
  }

  static String? _messageFromErrorBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      return message != null && message.isNotEmpty ? message : null;
    }

    String? asText;
    if (data is List<int>) {
      asText = utf8.decode(data, allowMalformed: true);
    } else if (data is String) {
      asText = data;
    }
    if (asText == null || asText.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(asText);
      if (decoded is Map && decoded['message'] is String) {
        final message = decoded['message'] as String;
        return message.isNotEmpty ? message : null;
      }
    } catch (_) {
      // Body is not JSON (e.g. HTML error page).
    }
    return null;
  }

  static String? _fileNameFromContentDisposition(String? header) {
    if (header == null || header.isEmpty) return null;

    final match = RegExp(
      r'''filename\*?=(?:UTF-8'')?["']?([^";]+)["']?''',
      caseSensitive: false,
    ).firstMatch(header);
    final rawName = match?.group(1)?.trim();
    if (rawName == null || rawName.isEmpty) return null;

    var name = rawName;
    try {
      name = Uri.decodeComponent(rawName);
    } catch (_) {
      // Keep the raw token if it is not percent-encoded.
    }

    name = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (name.isEmpty) return null;
    if (!name.toLowerCase().endsWith('.pdf')) {
      name = '$name.pdf';
    }
    return name;
  }

  static bool _isPdfBytes(Uint8List bytes) {
    if (bytes.length < 5) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }
}
