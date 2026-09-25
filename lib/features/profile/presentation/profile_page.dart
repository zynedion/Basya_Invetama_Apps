import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/domain/auth_profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.profile,
    required this.onLogout,
    this.loggingOut = false,
    this.onEditProfile,
    this.onChangePassword,
  });

  final AuthProfile? profile;
  final VoidCallback onLogout;
  final bool loggingOut;
  final VoidCallback? onEditProfile;
  final VoidCallback? onChangePassword;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const ValueKey('profile-page-scroll'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 142),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil',
                  key: const ValueKey('page-title-profil'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _MemberCard(profile: profile),
                const SizedBox(height: 32),
                const _SectionTitle('Informasi akun'),
                const SizedBox(height: 14),
                _AccountInformation(profile: profile),
                const SizedBox(height: 32),
                const _SectionTitle('Pengaturan akun'),
                const SizedBox(height: 14),
                BasyaActionButton(
                  label: 'Edit profil',
                  icon: Icons.manage_accounts_outlined,
                  style: BasyaActionStyle.emphasis,
                  onPressed: onEditProfile,
                  expand: true,
                ),
                const SizedBox(height: 12),
                BasyaActionButton(
                  label: 'Ganti password',
                  icon: Icons.key_rounded,
                  style: BasyaActionStyle.secondary,
                  onPressed: onChangePassword,
                  expand: true,
                ),
                const SizedBox(height: 28),
                BasyaActionButton(
                  key: const ValueKey('temporary-logout-button'),
                  label: loggingOut ? 'Keluar...' : 'Keluar dari akun',
                  icon: Icons.logout_rounded,
                  style: BasyaActionStyle.danger,
                  onPressed: loggingOut ? null : onLogout,
                  expand: true,
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Basya Investama · v1.0.0',
                    style: TextStyle(
                      color: Color(0xFF8A969C),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.ink,
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.profile});

  final AuthProfile? profile;

  String get _name => profile?.displayName ?? 'Anggota Basya';

  String get _memberNumber {
    return _available(profile?.nasabah?.memberNumber);
  }

  String get _joinedAt {
    final date = profile?.nasabah?.joinedAt;
    if (date == null) return 'Belum tersedia';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final investor = profile?.hasInvestorProfile == true;
    final active = profile?.nasabah?.active;
    return Container(
      key: const ValueKey('profile-member-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.heroGradientColors,
          stops: AppTheme.heroGradientStops,
        ),
        borderRadius: BorderRadius.circular(AppTheme.heroRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33006A66),
            offset: Offset(0, 14),
            blurRadius: 30,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -34,
            top: -48,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x5CC7FFE6), Color(0x00C7FFE6)],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BrandMark(),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'KARTU ANGGOTA',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Color(0xFFD5F3E9),
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _ProfileAvatar(profile: profile),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Nomor anggota',
                          style: TextStyle(
                            color: Color(0xFFD5F3E9),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _memberNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            letterSpacing: .5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bergabung sejak',
                          style: TextStyle(
                            color: Color(0xFFD5F3E9),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _joinedAt,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (active != null)
                    _GlassBadge(
                      icon: active
                          ? Icons.verified_outlined
                          : Icons.error_outline_rounded,
                      label: active ? 'Aktif' : 'Tidak aktif',
                    ),
                  if (investor) const _GlassBadge(label: 'Investor'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    height: 34,
    child: Image.asset(
      'assets/logo/logo_basya.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => const Text(
        'BASYA',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppTheme.teal,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final AuthProfile? profile;

  @override
  Widget build(BuildContext context) {
    final url = profile?.avatarUrl;
    final name = profile?.displayName.trim() ?? '';
    final initial = name.isEmpty ? 'B' : name.characters.first.toUpperCase();
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFFDDF8EA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xA6FFFFFF), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppTheme.teal,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppTheme.teal,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 28),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0x24FFFFFF),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0x5CFFFFFF)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: const Color(0xFFBFFFE5)),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _AccountInformation extends StatelessWidget {
  const _AccountInformation({required this.profile});

  final AuthProfile? profile;

  @override
  Widget build(BuildContext context) {
    final email = profile?.email.trim() ?? '';
    final member = profile?.nasabah;
    final investor = profile?.investor;
    final bankDetails = [
      member?.bankName,
      member?.accountNumber,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.softShadow,
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: email.isEmpty ? 'Belum tersedia' : email,
          ),
          _InformationRow(
            icon: Icons.smartphone_rounded,
            label: 'Nomor telepon',
            value: _available(member?.contact),
          ),
          _InformationRow(
            icon: Icons.account_balance_outlined,
            label: 'Rekening pencairan',
            value: _available(bankDetails),
          ),
          _InformationRow(
            icon: Icons.person_outline_rounded,
            label: 'Nama pemilik rekening',
            value: _available(member?.accountName),
          ),
          _InformationRow(
            icon: Icons.shield_outlined,
            label: 'Status keanggotaan',
            value: _status(member?.active),
            valueColor: _statusColor(member?.active),
            showDivider: investor != null,
          ),
          if (investor != null) ...[
            _InformationRow(
              icon: Icons.badge_outlined,
              label: 'Nomor investor',
              value: _available(investor.registrationNumber),
            ),
            _InformationRow(
              icon: Icons.verified_user_outlined,
              label: 'Status investor',
              value: _status(investor.active),
              valueColor: _statusColor(investor.active),
              showDivider: false,
            ),
          ],
        ],
      ),
    );
  }
}

String _available(String? value) =>
    value == null || value.trim().isEmpty ? 'Belum tersedia' : value.trim();

String _status(bool? value) => switch (value) {
  true => 'Aktif',
  false => 'Tidak aktif',
  null => 'Belum tersedia',
};

Color _statusColor(bool? value) => switch (value) {
  true => const Color(0xFF00865D),
  false => AppTheme.negative,
  null => AppTheme.muted,
};

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppTheme.ink,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF7F5),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppTheme.teal, size: 19),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: Color(0xFFE7EEEC)))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
