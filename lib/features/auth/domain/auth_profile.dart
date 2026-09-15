class AuthProfile {
  const AuthProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.photo,
    required this.groupLevel,
    required this.active,
    required this.hasNasabahProfile,
    required this.hasInvestorProfile,
  });

  final String id;
  final String username;
  final String fullName;
  final String email;
  final String photo;
  final String groupLevel;
  final bool active;
  final bool hasNasabahProfile;
  final bool hasInvestorProfile;

  String get displayName {
    final name = fullName.trim();
    if (name.isNotEmpty) return name;
    final fallback = username.trim();
    return fallback.isEmpty ? 'Anggota Basya' : fallback;
  }

  /// Akun internal mendapat tampilan investor untuk kebutuhan development.
  /// Otorisasi endpoint tetap harus ditentukan oleh backend.
  bool get usesInvestorHome {
    if (hasInvestorProfile) return true;
    return const {
      'root',
      'administrator',
      'mgr',
    }.contains(groupLevel.trim().toLowerCase());
  }

  String? get avatarUrl {
    final value = photo.trim();
    if (value.isEmpty || value.toLowerCase() == 'default.png') return null;
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme ? value : null;
  }
}
