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
    this.nasabah,
    this.investor,
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
  final NasabahProfile? nasabah;
  final InvestorProfile? investor;

  String get displayName {
    final name = fullName.trim();
    if (name.isNotEmpty) return name;
    final memberName = nasabah?.fullName.trim() ?? '';
    if (memberName.isNotEmpty) return memberName;
    final investorName = investor?.fullName.trim() ?? '';
    if (investorName.isNotEmpty) return investorName;
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

String _text(Map data, String key) => data[key]?.toString().trim() ?? '';

bool? _flag(Map data, String key) => switch (_text(data, key).toUpperCase()) {
  'Y' => true,
  'N' => false,
  _ => null,
};

class NasabahProfile {
  const NasabahProfile({
    required this.id,
    required this.memberNumber,
    required this.fullName,
    required this.contact,
    required this.joinedAt,
    required this.bankId,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.kycVerified,
    required this.active,
  });

  factory NasabahProfile.fromJson(Map data) => NasabahProfile(
    id: _text(data, 'id'),
    memberNumber: _text(data, 'id_nasabah'),
    fullName: _text(data, 'full_name'),
    contact: _text(data, 'contact'),
    joinedAt: DateTime.tryParse(_text(data, 'joined_at')),
    bankId: _text(data, 'bank_id'),
    bankName: _text(data, 'bank_name'),
    accountNumber: _text(data, 'norek'),
    accountName: _text(data, 'account_name'),
    kycVerified: _flag(data, 'kyc_status'),
    active: _flag(data, 'flag'),
  );

  final String id;
  final String memberNumber;
  final String fullName;
  final String contact;
  final DateTime? joinedAt;
  final String bankId;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final bool? kycVerified;
  final bool? active;
}

class InvestorProfile {
  const InvestorProfile({
    required this.id,
    required this.nasabahId,
    required this.registrationNumber,
    required this.fullName,
    required this.kycVerified,
    required this.active,
  });

  factory InvestorProfile.fromJson(Map data) => InvestorProfile(
    id: _text(data, 'id'),
    nasabahId: _text(data, 'nasabah_id'),
    registrationNumber: _text(data, 'reg_id'),
    fullName: _text(data, 'fullname'),
    kycVerified: _flag(data, 'kyc_status'),
    active: _flag(data, 'flag'),
  );

  final String id;
  final String nasabahId;
  final String registrationNumber;
  final String fullName;
  final bool? kycVerified;
  final bool? active;
}
