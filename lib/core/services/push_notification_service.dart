import 'dart:async';

import '../utils/platform_helper.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:timezone/data/latest.dart' as tz_data;

import 'package:timezone/timezone.dart' as tz;

import '../../features/adhkar/config/adhkar_reminder_config.dart';

import '../../app/models/app_role.dart';

import '../../app/providers/app_role_provider.dart';

import '../../features/auth/providers/auth_provider.dart';

import '../../features/chat/providers/active_chat_conversation.dart';
import '../../features/chat/utils/chat_notification_launcher.dart';

import '../../features/teacher/auth/models/auth_user.dart';
import '../../features/teacher/auth/providers/auth_providers.dart';

import '../../firebase_options.dart';

import 'device_token_api.dart';

import 'foreground_push_message.dart';

import 'teacher_device_token_api.dart';



typedef MeetingPushHandler = void Function(int meetingId);

typedef ChatPushHandler = void Function(ChatPushTarget target);

typedef AdhkarPushHandler = void Function(String groupId);



@pragma('vm:entry-point')

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

}



class PushNotificationService {

  PushNotificationService(

    this._parentDeviceTokenApi,

    this._teacherDeviceTokenApi,

  );



  final DeviceTokenApi _parentDeviceTokenApi;

  final TeacherDeviceTokenApi _teacherDeviceTokenApi;

  final FlutterLocalNotificationsPlugin _localNotifications =

      FlutterLocalNotificationsPlugin();



  bool _initialized = false;

  String? _currentToken;

  MeetingPushHandler? _onMeetingOpened;

  ChatPushHandler? _onChatOpened;

  AdhkarPushHandler? _onAdhkarOpened;

  WidgetRef? _ref;



  static const _meetingsChannelId = 'masged_meetings';

  static const _meetingsChannelName = 'مكالمات الفيديو';

  static const _chatChannelId = 'masged_chat';

  static const _chatChannelName = 'رسائل المحادثة';

  static const _adhkarChannelId = 'adhkar_reminders';

  static const _adhkarChannelName = 'تذكير الأذكار';

  static const _androidNotificationColor = Color(0xFF0D5C6D);

  static bool _timezonesInitialized = false;



  Future<void> initialize(

    WidgetRef ref, {

    MeetingPushHandler? onMeetingOpened,

    ChatPushHandler? onChatOpened,

    AdhkarPushHandler? onAdhkarOpened,

  }) async {

    if (_initialized) return;

    _ref = ref;

    _onMeetingOpened = onMeetingOpened;

    _onChatOpened = onChatOpened;

    _onAdhkarOpened = onAdhkarOpened;



    try {

      await Firebase.initializeApp(

        options: DefaultFirebaseOptions.currentPlatform,

      );

    } catch (e) {

      debugPrint('Firebase init skipped: $e');

      return;

    }



    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);



    await _setupLocalNotifications();

    await _requestPermissions();



    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);



    final initial = await FirebaseMessaging.instance.getInitialMessage();

    if (initial != null) {

      _handleOpenedMessage(initial);

    }



    _currentToken = await _resolveFcmToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {

      _currentToken = token;

      await syncRegistration();

    });



    _initialized = true;

    await syncRegistration();

  }



  /// On iOS, FCM token is unavailable until APNs token arrives.
  Future<String?> _resolveFcmToken() async {
    if (isIOS) {
      for (var i = 0; i < 10; i++) {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null && apns.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      debugPrint('Push iOS APNS token: ${apns == null ? "null" : "ok"}');
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint(
        'Push FCM token (${_platformLabel()}): '
        '${token == null || token.isEmpty ? "null" : "${token.substring(0, token.length.clamp(0, 12))}…"}',
      );
      return token;
    } catch (e) {
      debugPrint('Push getToken failed: $e');
      return null;
    }
  }



  Future<void> syncRegistration() async {

    if (!_initialized || _ref == null) return;



    final token = _currentToken ?? await _resolveFcmToken();

    if (token == null || token.isEmpty) {
      debugPrint('Push sync skipped: no FCM token yet (${_platformLabel()})');
      return;
    }

    _currentToken = token;



    final role = _ref!.read(appRoleProvider);

    final platform = _platformLabel();



    try {

      if (role == AppRole.teacher) {

        final teacher = _ref!.read(authControllerProvider).valueOrNull;

        if (teacher == null || !teacher.isSessionValid) return;

        await _teacherDeviceTokenApi.register(

          fcmToken: token,

          platform: platform,

        );

        return;

      }



      final auth = _ref!.read(authProvider);

      if (!auth.isAuthenticated) return;

      await _parentDeviceTokenApi.register(

        fcmToken: token,

        platform: platform,

      );

    } catch (e) {

      debugPrint('FCM register failed: $e');

    }

  }



  Future<void> unregister() async {

    final token = _currentToken ?? await FirebaseMessaging.instance.getToken();

    if (token == null || token.isEmpty) return;



    final role = _ref?.read(appRoleProvider);

    try {

      if (role == AppRole.teacher) {

        await _teacherDeviceTokenApi.unregister(fcmToken: token);

      } else {

        await _parentDeviceTokenApi.unregister(fcmToken: token);

      }

    } catch (e) {

      debugPrint('FCM unregister failed: $e');

    }

  }



  Future<void> _requestPermissions() async {

    await FirebaseMessaging.instance.requestPermission(

      alert: true,

      badge: true,

      sound: true,

    );

    if (isIOS) {

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(

        alert: false,

        badge: true,

        sound: false,

      );

    }

  }



  Future<void> _setupLocalNotifications() async {

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');

    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(

      android: androidInit,

      iOS: iosInit,

    );



    await _localNotifications.initialize(

      initSettings,

      onDidReceiveNotificationResponse: (response) {

        final payload = response.payload;

        if (payload == null) return;

        if (payload.startsWith('meet:')) {

          final id = int.tryParse(payload.substring(5));

          if (id != null) _openMeeting(id);

        } else if (payload.startsWith('chat:')) {

          final target = _parseChatPayload(payload.substring(5));

          if (target != null) _openChat(target);

        } else if (payload.startsWith('adhkar:')) {

          _openAdhkar(payload.substring(7));

        }

      },

    );



    if (isAndroid) {

      final plugin = _localNotifications.resolvePlatformSpecificImplementation<

          AndroidFlutterLocalNotificationsPlugin>();

      await plugin?.createNotificationChannel(

        AndroidNotificationChannel(

          _meetingsChannelId,

          _meetingsChannelName,

          description: 'إشعارات مكالمات الفيديو من المعلم',

          importance: Importance.high,

          enableLights: true,

          ledColor: _androidNotificationColor,

          enableVibration: true,

          playSound: true,

        ),

      );

      await plugin?.createNotificationChannel(

        AndroidNotificationChannel(

          _chatChannelId,

          _chatChannelName,

          description: 'إشعارات رسائل المحادثة',

          importance: Importance.high,

          enableLights: true,

          ledColor: _androidNotificationColor,

          enableVibration: true,

          playSound: true,

        ),

      );

      await plugin?.createNotificationChannel(

        AndroidNotificationChannel(

          _adhkarChannelId,

          _adhkarChannelName,

          description: 'تذكير أذكار الصباح والمساء',

          importance: Importance.defaultImportance,

          enableLights: true,

          ledColor: _androidNotificationColor,

          enableVibration: true,

          playSound: true,

        ),

      );

    }

  }



  void _showForegroundNotification(RemoteMessage message) {

    final notification = message.notification;

    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'إشعار';

    final body = notification?.body ?? data['body'] ?? 'لديك إشعار جديد';

    final kind = data['kind']?.toString();

    final isMeeting = kind == 'meet';

    final isChat = kind == 'chat';

    final meetingId = isMeeting

        ? int.tryParse(data['meetingId']?.toString() ?? '')

        : null;

    final chatTarget = isChat ? _parseChatData(data) : null;

    if (isChat && chatTarget != null) {
      if (ActiveChatConversationTracker.isActive(
        teacherId: chatTarget.teacherId,
        studentId: chatTarget.studentId,
      )) {
        return;
      }
    }

    _ref?.read(foregroundPushMessageProvider.notifier).state =

        ForegroundPushMessage(

      title: title,

      body: body,

      isMeeting: isMeeting,

      meetingId: meetingId,

      isChat: isChat,

      teacherId: chatTarget?.teacherId,

      studentId: chatTarget?.studentId,

      teacherName: chatTarget?.teacherName,

      studentName: chatTarget?.studentName,

      parentPhone: chatTarget?.parentPhone,

    );

  }



  void _handleOpenedMessage(RemoteMessage message) {

    final data = message.data;

    final kind = data['kind']?.toString();

    if (kind == 'meet') {

      final meetingId = int.tryParse(data['meetingId']?.toString() ?? '');

      if (meetingId != null) _openMeeting(meetingId);

      return;

    }

    if (kind == 'chat') {

      final target = _parseChatData(data);

      if (target != null) _openChat(target);

    }

  }



  ChatPushTarget? _parseChatData(Map<String, dynamic> data) {

    final teacherId = int.tryParse(data['teacherId']?.toString() ?? '');

    final studentId = int.tryParse(data['studentId']?.toString() ?? '');

    if (teacherId == null || studentId == null) return null;



    return ChatPushTarget(

      teacherId: teacherId,

      studentId: studentId,

      teacherName: data['teacherName']?.toString(),

      studentName: data['studentName']?.toString(),

      parentPhone: data['parentPhone']?.toString(),

    );

  }



  ChatPushTarget? _parseChatPayload(String payload) {

    final parts = payload.split(':');

    if (parts.length < 2) return null;

    final teacherId = int.tryParse(parts[0]);

    final studentId = int.tryParse(parts[1]);

    if (teacherId == null || studentId == null) return null;

    return ChatPushTarget(teacherId: teacherId, studentId: studentId);

  }



  void _openMeeting(int meetingId) {

    _onMeetingOpened?.call(meetingId);

  }



  void _openChat(ChatPushTarget target) {

    _onChatOpened?.call(target);

  }



  void _openAdhkar(String groupId) {

    if (groupId.isEmpty) return;

    _onAdhkarOpened?.call(groupId);

  }



  Future<void> _ensureTimezonesInitialized() async {

    if (_timezonesInitialized) return;

    tz_data.initializeTimeZones();

    tz.setLocalLocation(tz.local);

    _timezonesInitialized = true;

  }



  Future<void> syncAdhkarReminders({

    required bool morningComplete,

    required bool eveningComplete,

  }) async {

    if (kIsWeb) return;

    await _ensureTimezonesInitialized();

    await _localNotifications.cancel(AdhkarReminderConfig.morningNotificationId);

    await _localNotifications.cancel(AdhkarReminderConfig.eveningNotificationId);



    const androidDetails = AndroidNotificationDetails(

      _adhkarChannelId,

      _adhkarChannelName,

      importance: Importance.defaultImportance,

      priority: Priority.defaultPriority,

    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(

      android: androidDetails,

      iOS: iosDetails,

    );



    if (!morningComplete) {

      final scheduled = _nextDailyTime(

        AdhkarReminderConfig.morningNotifyHour,

        AdhkarReminderConfig.morningNotifyMinute,

      );

      await _localNotifications.zonedSchedule(

        AdhkarReminderConfig.morningNotificationId,

        'صباح الخير',

        'لا تنس أذكار الصباح اليوم',

        scheduled,

        details,

        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

        matchDateTimeComponents: DateTimeComponents.time,

        payload: 'adhkar:morning',

      );

    }



    if (!eveningComplete) {

      final scheduled = _nextDailyTime(

        AdhkarReminderConfig.eveningNotifyHour,

        AdhkarReminderConfig.eveningNotifyMinute,

      );

      await _localNotifications.zonedSchedule(

        AdhkarReminderConfig.eveningNotificationId,

        'مساء الخير',

        'حان وقت أذكار المساء',

        scheduled,

        details,

        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

        matchDateTimeComponents: DateTimeComponents.time,

        payload: 'adhkar:evening',

      );

    }

  }



  tz.TZDateTime _nextDailyTime(int hour, int minute) {

    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(

      tz.local,

      now.year,

      now.month,

      now.day,

      hour,

      minute,

    );

    if (scheduled.isBefore(now)) {

      scheduled = scheduled.add(const Duration(days: 1));

    }

    return scheduled;

  }



  String _platformLabel() {
    if (kIsWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    return 'unknown';
  }

}



final deviceTokenApiProvider = Provider<DeviceTokenApi>((ref) {

  return DeviceTokenApi();

});



final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {

  return PushNotificationService(

    ref.watch(deviceTokenApiProvider),

    ref.watch(teacherDeviceTokenApiProvider),

  );

});



final pushNotificationBootstrapProvider = Provider<void>((ref) {

  ref.listen<AuthState>(authProvider, (previous, next) {

    if (ref.read(appRoleProvider) != AppRole.parent) return;

    final push = ref.read(pushNotificationServiceProvider);

    if (next.isAuthenticated) {

      unawaited(push.syncRegistration());

    } else if (previous?.isAuthenticated == true && !next.isAuthenticated) {

      unawaited(push.unregister());

    }

  });



  ref.listen<AsyncValue<AuthUser?>>(authControllerProvider, (previous, next) {

    if (ref.read(appRoleProvider) != AppRole.teacher) return;

    final push = ref.read(pushNotificationServiceProvider);

    final wasLoggedIn = previous?.valueOrNull?.isSessionValid == true;

    final isLoggedIn = next.valueOrNull?.isSessionValid == true;

    if (isLoggedIn) {

      unawaited(push.syncRegistration());

    } else if (wasLoggedIn && !isLoggedIn) {

      unawaited(push.unregister());

    }

  });



  ref.listen<AppRole?>(appRoleProvider, (previous, next) {

    if (previous == next) return;

    unawaited(ref.read(pushNotificationServiceProvider).syncRegistration());

  });

});

