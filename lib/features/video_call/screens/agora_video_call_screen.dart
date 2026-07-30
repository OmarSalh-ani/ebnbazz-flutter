import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/network/signalr_hub_connector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../config/agora_config.dart';
import '../models/video_call_participant.dart';
import '../models/video_call_session.dart';
import '../models/video_call_uid.dart';
import '../providers/video_call_providers.dart';
import '../utils/video_call_participant_utils.dart';
import '../widgets/audio_sound_waves.dart';
import '../widgets/meeting_student_picker_sheet.dart';
import 'meeting_quran_screen.dart';
import '../../teacher/attendance/providers/attendance_providers.dart';
import '../../teacher/dashboard/models/dashboard_models.dart';

/// In-app Agora call: teacher/parent share this screen; mic gating uses SignalR `/hubs/video-call`.
class AgoraVideoCallScreen extends ConsumerStatefulWidget {
  const AgoraVideoCallScreen({
    super.key,
    required this.session,
    required this.hubJwt,
  });

  final VideoCallSession session;
  final String hubJwt;

  @override
  ConsumerState<AgoraVideoCallScreen> createState() =>
      _AgoraVideoCallScreenState();
}

class _AgoraVideoCallScreenState extends ConsumerState<AgoraVideoCallScreen> {
  RtcEngine? _engine;
  HubConnection? _hub;
  late final RtcEngineEventHandler _eventHandler;
  late final TextEditingController _notesController;
  Timer? _notesSaveTimer;
  Timer? _durationTimer;
  DateTime? _joinedAt;

  final Set<int> _remoteUids = {};
  bool _initializing = true;
  String? _error;
  bool _joined = false;

  bool _localVideoEnabled = true;
  bool _localAudioMuted = false;
  bool _addingStudents = false;

  /// Parent: whether we publish mic to the channel (teacher-controlled).
  bool _parentMicPublished = false;

  /// Parent: whether we publish camera to the channel (teacher-controlled).
  bool _parentCameraPublished = true;

  /// Parent: hand raised for a question.
  bool _handRaised = false;

  /// Teacher: students who raised their hand.
  final Set<int> _raisedHands = {};

  /// Teacher: last known mic grant per student id (parent UIDs).
  final Map<int, bool> _studentMicAllowed = {};

  /// Teacher: last known camera grant per student id (parent UIDs).
  final Map<int, bool> _studentCameraAllowed = {};

  /// Teacher: student id → display info for mic toolbar.
  late final Map<int, VideoCallParticipantInfo> _participantsByStudentId;

  /// RTC uid → latest audio volume (0–255) for speaking indicator.
  final Map<int, int> _speakingVolumeByUid = {};

  /// Loudest remote speaker from Agora (supplements top-3 volume list).
  int? _activeSpeakerUid;

  /// RTC uid → whether remote video is actively decoding.
  final Map<int, bool> _remoteVideoPublishing = {};

  /// Forces [AgoraVideoView] rebuild when a remote user rejoins.
  final Map<int, int> _remoteVideoGeneration = {};

  static const int _speakingVolumeThreshold = 10;

  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _participantsByStudentId = Map<int, VideoCallParticipantInfo>.from(
      widget.session.participantsByStudentId,
    );
    for (final sid in widget.session.participantsByStudentId.keys) {
      _studentMicAllowed.putIfAbsent(sid, () => false);
      _studentCameraAllowed.putIfAbsent(sid, () => true);
    }
    if (!widget.session.isTeacher) {
      _parentMicPublished = false;
    } else {
      _parentMicPublished = true;
    }
    _eventHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (mounted) {
          setState(() {
            _joined = true;
            _joinedAt ??= DateTime.now();
          });
          _startDurationTimer();
          final engine = _engine;
          if (engine != null) {
            unawaited(
              engine.enableAudioVolumeIndication(
                interval: 200,
                smooth: 3,
                reportVad: true,
              ),
            );
          }
          if (!widget.session.isTeacher) {
            unawaited(_syncLocalMediaAfterJoin());
          }
        }
      },
      onActiveSpeaker: (connection, uid) {
        if (!mounted || uid == 0) return;
        if (!_isStudentRtcUid(uid)) return;
        if (_activeSpeakerUid == uid) return;
        setState(() => _activeSpeakerUid = uid);
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (remoteUid == widget.session.uid) return;
        if (mounted) {
          setState(() {
            _remoteUids.add(remoteUid);
            _remoteVideoGeneration[remoteUid] =
                (_remoteVideoGeneration[remoteUid] ?? 0) + 1;
            final sid = VideoCallUid.studentIdFromRtcUid(remoteUid);
            if (sid != null) {
              _studentMicAllowed.putIfAbsent(sid, () => false);
              _studentCameraAllowed.putIfAbsent(sid, () => true);
              _participantsByStudentId.putIfAbsent(
                sid,
                () => widget.session.participantsByStudentId[sid] ??
                    VideoCallParticipantInfo(
                      studentId: sid,
                      fullName: 'طالب',
                    ),
              );
            }
          });
        }
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (mounted) {
          setState(() {
            _remoteUids.remove(remoteUid);
            _remoteVideoGeneration.remove(remoteUid);
            _speakingVolumeByUid.remove(remoteUid);
            _remoteVideoPublishing.remove(remoteUid);
            final sid = VideoCallUid.studentIdFromRtcUid(remoteUid);
            if (sid != null) {
              _studentMicAllowed.remove(sid);
              _studentCameraAllowed.remove(sid);
              _raisedHands.remove(sid);
            }
          });
        }
      },
      onRemoteVideoStateChanged:
          (connection, remoteUid, state, reason, elapsed) {
        if (!mounted) return;
        final publishing =
            state == RemoteVideoState.remoteVideoStateDecoding;
        if (_remoteVideoPublishing[remoteUid] == publishing) return;
        setState(() {
          _remoteVideoPublishing[remoteUid] = publishing;
        });
      },
      onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
        if (!mounted) return;
        final reportedUids = <int>{};
        var changed = false;
        for (final speaker in speakers) {
          final uid = speaker.uid ?? 0;
          if (!_isStudentRtcUid(uid)) continue;
          reportedUids.add(uid);
          final vol = speaker.volume ?? 0;
          if (_speakingVolumeByUid[uid] != vol) {
            _speakingVolumeByUid[uid] = vol;
            changed = true;
          }
          if (vol >= _speakingVolumeThreshold && _activeSpeakerUid != uid) {
            _activeSpeakerUid = uid;
            changed = true;
          }
        }
        for (final uid in _remoteUids.where(_isStudentRtcUid)) {
          if (!reportedUids.contains(uid) && (_speakingVolumeByUid[uid] ?? 0) > 0) {
            _speakingVolumeByUid[uid] = 0;
            changed = true;
          }
        }
        if (_activeSpeakerUid != null &&
            !_remoteUids.contains(_activeSpeakerUid) &&
            (_speakingVolumeByUid[_activeSpeakerUid!] ?? 0) == 0) {
          _activeSpeakerUid = null;
          changed = true;
        }
        if (changed) setState(() {});
      },
      onError: (err, msg) {
        debugPrint('Agora onError: $err $msg');
      },
    );
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!cam.isGranted || !mic.isGranted) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'يلزم السماح بالكاميرا والميكروفون لإكمال المكالمة.';
        });
      }
      return;
    }

    try {
      await WakelockPlus.enable();
      final engine = createAgoraRtcEngine();
      await engine.initialize(
        RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      engine.registerEventHandler(_eventHandler);
      await engine.enableVideo();
      await engine.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      final publishMic = widget.session.isTeacher || _parentMicPublished;
      final publishCamera = widget.session.isTeacher
          ? _localVideoEnabled
          : _parentCameraPublished && _localVideoEnabled;
      await engine.joinChannel(
        token: widget.session.token,
        channelId: widget.session.channelName,
        uid: widget.session.uid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: publishCamera,
          publishMicrophoneTrack: publishMic,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      if (!mounted) {
        await _tearDown(engine, stopWakelock: true);
        return;
      }

      _engine = engine;
      await _setupHub();
      if (mounted) setState(() => _initializing = false);
    } catch (e, st) {
      debugPrint('$e\n$st');
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = e.toString();
        });
      }
      await _tearDown(_engine, stopWakelock: true);
    }
  }

  Future<void> _setupHub() async {
    try {
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.videoCallHubPath}'.trim();
      final hub = await SignalRHubConnector.connect(
        hubUrl: url,
        accessTokenFactory: () async => widget.hubJwt,
      );

      hub.on('micPermissionChanged', _onMicPermissionChanged);
      hub.on('cameraPermissionChanged', _onCameraPermissionChanged);
      hub.on('callEnded', _onCallEnded);
      hub.on('handRaised', _onHandRaised);
      hub.on('callStateSynced', _onCallStateSynced);
      if (!mounted) {
        await hub.stop();
        return;
      }
      _hub = hub;
      await hub.invoke('joinCall', args: [widget.session.meetingId]);
    } catch (e, st) {
      // Agora media still works; realtime mic/camera gating needs the hub.
      debugPrint('Video call hub unavailable: $e\n$st');
    }
  }

  void _onCallStateSynced(List<Object?>? args) {
    if (!mounted || widget.session.isTeacher) return;
    if (args == null || args.length < 2) return;
    final micAllowed = args[0] as bool;
    final cameraAllowed = args[1] as bool;
    unawaited(_applyParentMicPublish(micAllowed));
    unawaited(_applyParentCameraPublish(cameraAllowed));
  }

  Future<void> _syncLocalMediaAfterJoin() async {
    final engine = _engine;
    if (engine == null || widget.session.isTeacher) return;
    try {
      await engine.enableLocalVideo(true);
      await engine.enableAudio();
      await engine.updateChannelMediaOptions(
        ChannelMediaOptions(
          publishCameraTrack: _parentCameraPublished && _localVideoEnabled,
          publishMicrophoneTrack: _parentMicPublished,
        ),
      );
      await engine.muteLocalVideoStream(!(_parentCameraPublished && _localVideoEnabled));
      await engine.muteLocalAudioStream(!_parentMicPublished || _localAudioMuted);
      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('syncLocalMediaAfterJoin: $e\n$st');
    }
  }

  void _onHandRaised(List<Object?>? args) {
    if (!mounted || !widget.session.isTeacher) return;
    if (args == null || args.length < 2) return;
    final studentId = (args[0] as num).toInt();
    final raised = args[1] as bool;
    setState(() {
      if (raised) {
        _raisedHands.add(studentId);
      } else {
        _raisedHands.remove(studentId);
      }
    });
  }

  void _onCallEnded(List<Object?>? args) {
    if (!mounted || _leaving) return;
    if (args != null && args.isNotEmpty) {
      final endedId = (args[0] as num?)?.toInt();
      if (endedId != null && endedId != widget.session.meetingId) return;
    }
    unawaited(_leave(endedByTeacher: !widget.session.isTeacher));
  }

  void _onMicPermissionChanged(List<Object?>? args) {
    if (!mounted || widget.session.isTeacher) return;
    if (args == null || args.length < 2) return;
    final studentId = (args[0] as num).toInt();
    final allowed = args[1] as bool;
    final linked = widget.session.linkedStudentId;
    if (linked == null || studentId != linked) return;
    unawaited(_applyParentMicPublish(allowed));
  }

  void _onCameraPermissionChanged(List<Object?>? args) {
    if (!mounted || widget.session.isTeacher) return;
    if (args == null || args.length < 2) return;
    final studentId = (args[0] as num).toInt();
    final allowed = args[1] as bool;
    final linked = widget.session.linkedStudentId;
    if (linked == null || studentId != linked) return;
    unawaited(_applyParentCameraPublish(allowed));
  }

  Future<void> _applyParentMicPublish(bool allowed) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.updateChannelMediaOptions(
        ChannelMediaOptions(
          publishMicrophoneTrack: allowed,
        ),
      );
      await engine.muteLocalAudioStream(!allowed);
      if (mounted) {
        setState(() {
          _parentMicPublished = allowed;
          _localAudioMuted = !allowed;
        });
        if (allowed && _handRaised) {
          unawaited(_lowerHandIfRaised());
        }
      }
    } catch (e, st) {
      debugPrint('mic publish failed: $e\n$st');
    }
  }

  Future<void> _toggleLocalMute() async {
    final engine = _engine;
    if (engine == null) return;
    if (!widget.session.isTeacher && !_parentMicPublished) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لم يفعّل المعلّم المايكروفون بعد',
              style: AppFonts.cairo(),
            ),
          ),
        );
      }
      return;
    }
    final next = !_localAudioMuted;
    await engine.muteLocalAudioStream(next);
    setState(() => _localAudioMuted = next);
  }

  Future<void> _ensureLocalVideoReady(RtcEngine engine) async {
    await engine.enableVideo();
    await engine.enableLocalVideo(true);
  }

  Future<void> _applyParentCameraPublish(bool allowed) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      if (allowed) {
        await _ensureLocalVideoReady(engine);
      }
      await engine.updateChannelMediaOptions(
        ChannelMediaOptions(
          publishCameraTrack: allowed,
        ),
      );
      await engine.muteLocalVideoStream(!allowed);
      if (mounted) {
        setState(() {
          _parentCameraPublished = allowed;
          _localVideoEnabled = allowed;
        });
      }
    } catch (e, st) {
      debugPrint('camera publish failed: $e\n$st');
    }
  }

  Future<void> _toggleLocalVideo() async {
    final engine = _engine;
    if (engine == null) return;
    if (!widget.session.isTeacher && !_parentCameraPublished) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'أوقف المعلّم الكاميرا — لا يمكنك تشغيلها الآن',
              style: AppFonts.cairo(),
            ),
          ),
        );
      }
      return;
    }
    final next = !_localVideoEnabled;
    try {
      if (next) {
        await _ensureLocalVideoReady(engine);
      }
      await engine.muteLocalVideoStream(!next);
      await engine.updateChannelMediaOptions(
        ChannelMediaOptions(publishCameraTrack: next),
      );
      if (mounted) setState(() => _localVideoEnabled = next);
    } catch (e, st) {
      debugPrint('toggleLocalVideo: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر تشغيل الكاميرا. على المحاكي اختر مصدر الكاميرا (Camera) '
              'في نافذة MEmu ثم أعد المحاولة.',
              style: AppFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    final engine = _engine;
    if (engine == null || !_localVideoEnabled) return;
    try {
      await engine.switchCamera();
    } catch (e, st) {
      debugPrint('switchCamera: $e\n$st');
    }
  }

  Future<void> _teacherSetMicForStudent(int studentId, bool allowed) async {
    try {
      await _hub?.invoke('setMicAllowed', args: [
        widget.session.meetingId,
        studentId,
        allowed,
      ]);
      if (mounted) {
        setState(() {
          _studentMicAllowed[studentId] = allowed;
          if (allowed) {
            _raisedHands.remove(studentId);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), style: AppFonts.cairo())),
        );
      }
    }
  }

  Future<void> _teacherSetCameraForStudent(int studentId, bool allowed) async {
    try {
      await _hub?.invoke('setCameraAllowed', args: [
        widget.session.meetingId,
        studentId,
        allowed,
      ]);
      if (mounted) {
        setState(() => _studentCameraAllowed[studentId] = allowed);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), style: AppFonts.cairo())),
        );
      }
    }
  }

  void _scheduleNotesSave() {
    if (!widget.session.isTeacher) return;
    _notesSaveTimer?.cancel();
    _notesSaveTimer = Timer(const Duration(milliseconds: 800), () {
      unawaited(_saveMeetingNotesDraft());
    });
  }

  Future<void> _saveMeetingNotesDraft() async {
    if (!widget.session.isTeacher || _hub == null) return;
    try {
      await _hub!.invoke('saveMeetingNotes', args: [
        widget.session.meetingId,
        _notesController.text.trim(),
      ]);
    } catch (e) {
      debugPrint('saveMeetingNotes failed: $e');
    }
  }

  Future<void> _toggleRaiseHand() async {
    final studentId = widget.session.linkedStudentId;
    if (studentId == null || _hub == null) return;
    final next = !_handRaised;
    try {
      if (next) {
        await _hub!.invoke('raiseHand', args: [
          widget.session.meetingId,
          studentId,
        ]);
      } else {
        await _hub!.invoke('lowerHand', args: [
          widget.session.meetingId,
          studentId,
        ]);
      }
      if (mounted) setState(() => _handRaised = next);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), style: AppFonts.cairo())),
        );
      }
    }
  }

  Future<void> _lowerHandIfRaised() async {
    if (!_handRaised || _hub == null) return;
    final studentId = widget.session.linkedStudentId;
    if (studentId == null) return;
    try {
      await _hub!.invoke('lowerHand', args: [
        widget.session.meetingId,
        studentId,
      ]);
    } catch (_) {}
    _handRaised = false;
  }

  Future<void> _confirmEndCall() async {
    final notes = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dialogNotes = TextEditingController(text: _notesController.text);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'إنهاء المكالمة؟',
              style: AppFonts.cairo(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'سيتم قطع الاتصال عن جميع المشاركين (أولياء الأمور).',
                    style: AppFonts.cairo(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dialogNotes,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات المكالمة (اختياري)',
                      labelStyle: AppFonts.cairo(),
                      border: const OutlineInputBorder(),
                    ),
                    style: AppFonts.cairo(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('إلغاء', style: AppFonts.cairo()),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.of(ctx).pop(dialogNotes.text.trim()),
                child: Text('إنهاء للجميع', style: AppFonts.cairo()),
              ),
            ],
          ),
        );
      },
    );
    if (notes == null || !mounted) return;
    _notesController.text = notes;
    await _endCall(notes: notes);
  }

  Future<void> _endCall({String? notes}) async {
    if (widget.session.isTeacher) {
      try {
        await _hub?.invoke('endCall', args: [
          widget.session.meetingId,
          notes ?? _notesController.text.trim(),
        ]);
      } catch (e) {
        debugPrint('endCall hub failed: $e');
      }
    }
    await _leave();
  }

  Future<void> _leave({bool endedByTeacher = false}) async {
    if (_leaving) return;
    _leaving = true;
    _notesSaveTimer?.cancel();
    await _lowerHandIfRaised();
    await _tearDown(_engine, stopWakelock: true);
    _engine = null;
    try {
      await _hub?.stop();
    } catch (_) {}
    _hub = null;
    if (mounted) {
      if (endedByTeacher) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'انتهت المكالمة من قبل المعلّم',
              style: AppFonts.cairo(),
            ),
          ),
        );
      }
      Navigator.of(context).pop();
    }
  }

  Future<void> _tearDown(RtcEngine? engine, {required bool stopWakelock}) async {
    if (engine != null) {
      try {
        engine.unregisterEventHandler(_eventHandler);
        await engine.leaveChannel();
        await engine.release();
      } catch (_) {}
    }
    if (stopWakelock) {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  String _formatMeetingStart(DateTime time) {
    return intl.DateFormat('yyyy/MM/dd hh:mm a').format(time);
  }

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String? _meetingTimeSubtitle() {
    final start = widget.session.startDateTime;
    final parts = <String>[];
    if (start != null) {
      parts.add(_formatMeetingStart(start));
    }
    if (_joinedAt != null) {
      parts.add('مدة ${_formatElapsed(DateTime.now().difference(_joinedAt!))}');
    }
    if (parts.isEmpty) return null;
    return parts.join('  •  ');
  }

  @override
  void dispose() {
    _notesSaveTimer?.cancel();
    _durationTimer?.cancel();
    _notesController.dispose();
    unawaited(_lowerHandIfRaised());
    if (!_leaving) {
      unawaited(_tearDown(_engine, stopWakelock: true));
      unawaited(_hub?.stop());
    }
    _engine = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;

    final meetingTimeSubtitle = _meetingTimeSubtitle();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        toolbarHeight: meetingTimeSubtitle != null ? 72 : kToolbarHeight,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: meetingTimeSubtitle != null ? 16 : null,
              ),
            ),
            if (meetingTimeSubtitle != null)
              Text(
                meetingTimeSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.cairo(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (widget.session.isTeacher)
            IconButton(
              icon: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF42A5F5),
                size: 28,
              ),
              tooltip: 'إجراءات سريعة',
              style: IconButton.styleFrom(
                foregroundColor: const Color(0xFF42A5F5),
              ),
              onPressed: _showTeacherQuickActionsSheet,
            ),
          if (_initializing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_error != null) {
              final isPermissionError = _error!.contains('الكاميرا والميكروفون');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppFonts.cairo(color: Colors.white70),
                      ),
                      if (isPermissionError) ...[
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: openAppSettings,
                          icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                          label: Text(
                            'فتح إعدادات التطبيق',
                            style: AppFonts.cairo(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            if (engine == null && _initializing) {
              return const Center(child: CircularProgressIndicator());
            }

            if (engine == null) {
              return const SizedBox.shrink();
            }

            final remotes = _displayRemoteUids()..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.session.isTeacher && _raisedHands.isNotEmpty)
                        _teacherRaisedHandsBanner(),
                      if (!widget.session.isTeacher) _parentStatusBanner(),
                      if (!widget.session.isTeacher &&
                          !_parentMicPublished &&
                          !_handRaised)
                        Container(
                          width: double.infinity,
                          color: Colors.deepOrange.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Text(
                            'في انتظار السماح من المعلّم لمشاركة الصوت',
                            textAlign: TextAlign.center,
                            style: AppFonts.cairo(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildRemoteVideosArea(
                              context: context,
                              engine: engine,
                              remotes: remotes,
                            ),
                            if (_localVideoEnabled)
                              Positioned(
                                top: 12,
                                right: 12,
                                width: 100,
                                height: 140,
                                child: _buildLocalPreview(engine),
                              ),
                          ],
                        ),
                      ),
                      if (widget.session.isTeacher)
                        Flexible(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.sizeOf(context).height * 0.38,
                            ),
                            child: _teacherMicToolbar(),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!widget.session.isTeacher)
                        _CallIconButton(
                          icon: _handRaised
                              ? Icons.front_hand
                              : Icons.front_hand_outlined,
                          label: _handRaised ? 'خفض اليد' : 'رفع اليد',
                          color: _handRaised ? Colors.amber.shade800 : null,
                          onTap: _toggleRaiseHand,
                        ),
                      _CallIconButton(
                        icon: _localAudioMuted ? Icons.mic_off : Icons.mic,
                        label: 'صوت',
                        highlighted: !widget.session.isTeacher &&
                            _parentMicPublished &&
                            _localAudioMuted,
                        onTap: _toggleLocalMute,
                      ),
                      _CallIconButton(
                        icon: _localVideoEnabled
                            ? Icons.videocam
                            : Icons.videocam_off,
                        label: 'كاميرا',
                        highlighted: !widget.session.isTeacher &&
                            _parentCameraPublished &&
                            !_localVideoEnabled,
                        onTap: _toggleLocalVideo,
                      ),
                      _CallIconButton(
                        icon: Icons.cameraswitch,
                        label: 'تبديل',
                        onTap: _switchCamera,
                      ),
                      _CallIconButton(
                        icon: Icons.call_end,
                        label: 'خروج',
                        color: Colors.redAccent,
                        onTap: widget.session.isTeacher ? _confirmEndCall : _leave,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<int> _displayRemoteUids() {
    final all = _remoteUids.toList();
    if (widget.session.isTeacher) {
      return all.where((uid) => !VideoCallUid.isTeacherRtcUid(uid)).toList();
    }
    final mainTeacher = widget.session.teacherRtcUid ??
        _remoteUids
            .where((uid) => VideoCallUid.isTeacherRtcUid(uid))
            .fold<int?>(null, (prev, uid) {
          if (prev == null) return uid;
          return uid < prev ? uid : prev;
        });
    final screenUid =
        mainTeacher != null ? VideoCallUid.teacherScreenUid(mainTeacher) : null;
    return all.where((uid) => uid != screenUid).toList();
  }

  Widget _buildRemoteVideosArea({
    required BuildContext context,
    required RtcEngine engine,
    required List<int> remotes,
  }) {
    if (remotes.isEmpty) {
      return Center(
        child: Text(
          _joined ? 'في انتظار انضمام الطرف الآخر…' : 'جاري الاتصال…',
          style: AppFonts.cairo(color: Colors.white54),
        ),
      );
    }

    if (remotes.length == 1) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: _buildRemoteVideoTile(
          engine: engine,
          uid: remotes.first,
        ),
      );
    }

    final crossAxisCount = remotes.length <= 4 ? 2 : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 9 / 16,
      ),
      itemCount: remotes.length,
      itemBuilder: (context, i) => _buildRemoteVideoTile(
        engine: engine,
        uid: remotes[i],
      ),
    );
  }

  bool _shouldShowRemoteVideo(int uid, int? studentId) {
    final cameraAllowed =
        studentId != null ? (_studentCameraAllowed[studentId] ?? true) : true;
    if (!cameraAllowed) return false;
    return _remoteVideoPublishing[uid] ?? false;
  }

  bool _isStudentRtcUid(int uid) => uid >= VideoCallUid.parentOffset;

  bool _uidIsSpeaking(int uid) {
    if (!_isStudentRtcUid(uid)) return false;
    if ((_speakingVolumeByUid[uid] ?? 0) >= _speakingVolumeThreshold) {
      return true;
    }
    return _activeSpeakerUid == uid;
  }

  bool _studentIsSpeaking(int studentId) {
    if (!(_studentMicAllowed[studentId] ?? false)) return false;
    return _uidIsSpeaking(VideoCallUid.parentUid(studentId));
  }

  Widget _speakingIndicator({double size = 26}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AudioSoundWaves(
        active: true,
        color: AppColors.success,
        size: size,
      ),
    );
  }

  Widget _buildParticipantAvatar(
    VideoCallParticipantInfo participant, {
    required double radius,
    Color? backgroundColor,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? AppColors.primary.withValues(alpha: 0.15),
      backgroundImage: participant.imageUrl != null
          ? NetworkImage(participant.imageUrl!)
          : null,
      child: participant.imageUrl == null
          ? Text(
              participant.firstName.isNotEmpty
                  ? participant.firstName[0]
                  : '?',
              style: AppFonts.cairo(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.85,
              ),
            )
          : null,
    );
  }

  Widget _buildCameraOffPlaceholder({VideoCallParticipantInfo? participant}) {
    return ColoredBox(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (participant != null)
              _buildParticipantAvatar(participant, radius: 36)
            else
              Icon(Icons.videocam_off, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              'الكاميرا متوقفة',
              style: AppFonts.cairo(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteVideoTile({
    required RtcEngine engine,
    required int uid,
  }) {
    final sid = VideoCallUid.studentIdFromRtcUid(uid);
    final participant =
        sid != null ? _participantsByStudentId[sid] : null;
    final showVideo = _shouldShowRemoteVideo(uid, sid);
    final speaking =
        widget.session.isTeacher && sid != null && _studentIsSpeaking(sid);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showVideo)
            ColoredBox(
              color: Colors.grey.shade900,
              child: AgoraVideoView(
                key: ValueKey('remote-$uid-${_remoteVideoGeneration[uid] ?? 0}'),
                controller: VideoViewController.remote(
                  rtcEngine: engine,
                  canvas: VideoCanvas(
                    uid: uid,
                    renderMode: RenderModeType.renderModeFit,
                  ),
                  connection: RtcConnection(
                    channelId: widget.session.channelName,
                  ),
                ),
              ),
            )
          else
            _buildCameraOffPlaceholder(participant: participant),
          if (speaking)
            Positioned(
              top: 8,
              left: 8,
              child: _speakingIndicator(size: 30),
            ),
          if (participant != null)
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  participant.firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.cairo(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocalPreview(RtcEngine engine) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.grey.shade800,
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: engine,
            canvas: const VideoCanvas(
              uid: 0,
              renderMode: RenderModeType.renderModeFit,
            ),
          ),
        ),
      ),
    );
  }

  Widget _teacherRaisedHandsBanner() {
    final count = _raisedHands.length;
    final names = _raisedHands
        .map((id) => _participantsByStudentId[id]?.firstName ?? 'طالب')
        .join('، ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.amber.shade700,
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.front_hand, color: Colors.black87, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? '$names يرفع يده — اضغط «إعطاء المايك للرد»'
                  : '$count طلاب يرفعون أيديهم ($names) — فعّل المايكروفون للرد',
              style: AppFonts.cairo(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _parentStatusBanner() {
    if (_handRaised && !_parentMicPublished) {
      return Container(
        width: double.infinity,
        color: Colors.amber.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.front_hand, color: Colors.amber.shade200, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'رفعت يدك — ينتظر المعلّم السماح بالمايكروفون',
                style: AppFonts.cairo(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_parentMicPublished && _localAudioMuted) {
      return Container(
        width: double.infinity,
        color: AppColors.success.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.mic, color: AppColors.successLight, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'يمكنك التحدث الآن — اضغط زر «صوت» بالأسفل لإلغاء الكتم',
                style: AppFonts.cairo(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_parentMicPublished && !_localAudioMuted) {
      return Container(
        width: double.infinity,
        color: AppColors.success.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Text(
          'المايكروفون مفعّل — يمكنك التحدث',
          textAlign: TextAlign.center,
          style: AppFonts.cairo(color: Colors.white, fontSize: 13),
        ),
      );
    }
    if (!_parentCameraPublished) {
      return Container(
        width: double.infinity,
        color: Colors.redAccent.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.videocam_off, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'أوقف المعلّم الكاميرا — انتظر السماح لتشغيلها',
                style: AppFonts.cairo(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showTeacherQuickActionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'إجراءات سريعة',
                style: AppFonts.cairo(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1, color: Colors.white),
              title: Text(
                'إضافة طلاب للمكالمة',
                style: AppFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'دعوة أولياء أمور جدد',
                style: AppFonts.cairo(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_showAddStudentsSheet());
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.white),
              title: Text(
                'فتح المصحف',
                style: AppFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'قراءة القرآن أثناء المكالمة (للمعلّم فقط)',
                style: AppFonts.cairo(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_openMeetingQuran());
              },
            ),
            ListTile(
              leading: const Icon(Icons.notes, color: Colors.white),
              title: Text(
                'ملاحظات المكالمة',
                style: AppFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'كتابة ملاحظات أثناء المكالمة',
                style: AppFonts.cairo(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showMeetingNotesSheet();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showMeetingNotesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ملاحظات المكالمة',
              style: AppFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              onChanged: (_) => _scheduleNotesSave(),
              maxLines: 5,
              autofocus: true,
              style: AppFonts.cairo(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'اكتب ملاحظاتك عن المكالمة…',
                hintStyle: AppFonts.cairo(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('تم', style: AppFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMeetingQuran() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const MeetingQuranScreen(),
      ),
    );
  }

  Future<void> _showAddStudentsSheet() async {
    final students = ref.read(attendanceStudentsProvider).value ?? const [];
    if (students.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يوجد طلاب في الحلقة',
              style: AppFonts.cairo(),
            ),
          ),
        );
      }
      return;
    }

    final invited = _participantsByStudentId.keys.toSet();
    final picked = await showMeetingStudentPickerSheet(
      context: context,
      students: students,
      alreadyInvitedIds: invited,
      title: 'إضافة طلاب للمكالمة',
      confirmLabel: 'دعوة الطلاب',
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    await _addStudentsToMeeting(picked, students);
  }

  Future<void> _addStudentsToMeeting(
    List<int> studentIds,
    List<StudentListItem> students,
  ) async {
    if (_addingStudents) return;
    setState(() => _addingStudents = true);
    try {
      final message = await ref.read(videoCallApiProvider).addStudentsToMeeting(
            meetingId: widget.session.meetingId,
            studentIds: studentIds,
          );
      final added = participantsForStudents(students, studentIds);
      if (mounted) {
        setState(() {
          _participantsByStudentId.addAll(added);
          for (final sid in studentIds) {
            _studentMicAllowed.putIfAbsent(sid, () => false);
            _studentCameraAllowed.putIfAbsent(sid, () => true);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: AppFonts.cairo()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), style: AppFonts.cairo())),
        );
      }
    } finally {
      if (mounted) setState(() => _addingStudents = false);
    }
  }

  Widget _teacherMicToolbar() {
    final studentIds = {
      ..._participantsByStudentId.keys,
      ..._studentMicAllowed.keys,
    }.toList()
      ..sort((a, b) {
        final ra = _raisedHands.contains(a);
        final rb = _raisedHands.contains(b);
        if (ra != rb) return ra ? -1 : 1;
        return a.compareTo(b);
      });
    if (studentIds.isEmpty) {
      return Container(
        color: Colors.black54,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.person_add_alt_1, color: Colors.white54, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'لا يوجد طلاب مدعوون — اضغط ⚡ لإضافة طلاب',
                style: AppFonts.cairo(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: studentIds.map((sid) {
            final allowed = _studentMicAllowed[sid] ?? false;
            final cameraAllowed = _studentCameraAllowed[sid] ?? true;
            final handRaised = _raisedHands.contains(sid);
            final speaking = _studentIsSpeaking(sid);
            final participant = _participantsByStudentId[sid] ??
                VideoCallParticipantInfo(studentId: sid, fullName: 'طالب');
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: handRaised ? 156 : 140,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: handRaised
                      ? Colors.amber.withValues(alpha: 0.28)
                      : speaking
                          ? AppColors.success.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: handRaised
                        ? Colors.amber.shade400
                        : speaking
                            ? AppColors.success
                            : allowed
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : Colors.white24,
                    width: handRaised || speaking ? 2.5 : 1,
                  ),
                  boxShadow: handRaised
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.45),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (speaking)
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.success,
                                width: 2.5,
                              ),
                            ),
                          ),
                        _buildParticipantAvatar(
                          participant,
                          radius: 26,
                          backgroundColor: handRaised
                              ? Colors.amber.withValues(alpha: 0.35)
                              : speaking
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : AppColors.primary.withValues(alpha: 0.15),
                        ),
                        if (speaking)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: _speakingIndicator(size: 24),
                          ),
                        if (handRaised)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.front_hand,
                                size: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (handRaised) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'يريد طرح سؤال',
                          style: AppFonts.cairo(
                            color: Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      participant.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.cairo(
                        color: handRaised ? Colors.amber.shade100 : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: handRaised && !allowed
                              ? Colors.green.shade700
                              : allowed
                                  ? Colors.orange.shade800
                                  : AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: () =>
                            _teacherSetMicForStudent(sid, !allowed),
                        icon: Icon(
                          allowed ? Icons.mic_off : Icons.mic,
                          size: 16,
                        ),
                        label: Text(
                          handRaised && !allowed
                              ? 'إعطاء المايك للرد'
                              : allowed
                                  ? 'كتم المايك'
                                  : 'إعطاء المايك',
                          style: AppFonts.cairo(fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: cameraAllowed
                              ? Colors.red.shade800
                              : AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: () =>
                            _teacherSetCameraForStudent(sid, !cameraAllowed),
                        icon: Icon(
                          cameraAllowed ? Icons.videocam_off : Icons.videocam,
                          size: 16,
                        ),
                        label: Text(
                          cameraAllowed ? 'إيقاف الكاميرا' : 'تشغيل الكاميرا',
                          style: AppFonts.cairo(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CallIconButton extends StatelessWidget {
  const _CallIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: highlighted
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  )
                : null,
            child: CircleAvatar(
              backgroundColor: color ??
                  (highlighted ? AppColors.success : Colors.white24),
              child: Icon(icon, color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppFonts.cairo(
              color: highlighted ? AppColors.successLight : Colors.white70,
              fontSize: 11,
              fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
