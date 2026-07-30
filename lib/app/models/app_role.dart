/// Selected entry mode for the unified Masged mobile app.
enum AppRole {
  parent,
  teacher,
}

extension AppRoleStorage on AppRole {
  String get storageKey => name;

  static AppRole? fromStorage(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final role in AppRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }
}
