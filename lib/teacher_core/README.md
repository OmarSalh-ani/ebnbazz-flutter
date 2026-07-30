# Teacher core (`lib/teacher_core`)

Teacher-specific infrastructure that is **not** shared with [`lib/core`](../core/):

| Area | Contents |
|---|---|
| Networking | [`api_client.dart`](network/api_client.dart), [`global_response.dart`](network/global_response.dart), [`api_exception.dart`](network/api_exception.dart) |
| Config | [`api_config.dart`](config/api_config.dart) |
| Storage | [`auth_storage.dart`](storage/auth_storage.dart) |
| Services | [`voice_command_service.dart`](services/voice_command_service.dart), [`location_service.dart`](services/location_service.dart), [`teacher_attendance_fingerprint_service.dart`](services/teacher_attendance_fingerprint_service.dart) |

Shared theme, validators, and prayer/mosque/quran services live under **`lib/core/`** (single source of truth).
