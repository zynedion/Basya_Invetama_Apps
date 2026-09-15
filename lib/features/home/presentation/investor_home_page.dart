import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/auth_gateway.dart';
import '../../auth/domain/auth_profile.dart';
import '../../auth/presentation/login_page.dart';
import '../domain/investor_home_data.dart';

const _homeScrollPhysics = BouncingScrollPhysics(
  parent: AlwaysScrollableScrollPhysics(),
);

class _HomeScrollBehavior extends MaterialScrollBehavior {
  const _HomeScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => _homeScrollPhysics;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

enum HomeAudience { investor, member }

class _HeroBalancePanelData {
  const _HeroBalancePanelData({required this.label, required this.amount});

  final String label;
  final int amount;
}

class _QuickActionData {
  const _QuickActionData(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _NavDestinationData {
  const _NavDestinationData(this.label, this.icon);

  final String label;
  final IconData icon;
}

class InvestorHomePage extends StatefulWidget {
  const InvestorHomePage({
    super.key,
    this.auth,
    this.profile,
    this.audience = HomeAudience.investor,
    this.data = InvestorHomeData.demo,
    this.memberData = MemberHomeData.demo,
    this.now,
  });

  final AuthGateway? auth;
  final AuthProfile? profile;
  final HomeAudience audience;
  final InvestorHomeData data;
  final MemberHomeData memberData;
  final DateTime Function()? now;

  @override
  State<InvestorHomePage> createState() => _InvestorHomePageState();
}

class _InvestorHomePageState extends State<InvestorHomePage> {
  late final AuthGateway _auth = widget.auth ?? AuthService();
  late HomeAudience _previewAudience = widget.audience;
  bool _balanceVisible = true;
  bool _loggingOut = false;
  Timer? _greetingTimer;
  late DateTime _currentTime;

  bool get _isInvestor => _previewAudience == HomeAudience.investor;

  String get _greeting {
    final hour = _currentTime.hour;
    if (hour >= 5 && hour < 11) return 'Selamat pagi,';
    if (hour >= 11 && hour < 15) return 'Selamat siang,';
    if (hour >= 15 && hour < 18) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  String get _memberName =>
      widget.profile?.displayName ??
      (_isInvestor ? widget.data.memberName : widget.memberData.memberName);

  String? get _avatarUrl => widget.profile == null
      ? (_isInvestor ? widget.data.avatarUrl : widget.memberData.avatarUrl)
      : widget.profile!.avatarUrl;

  int get _totalBalance =>
      _isInvestor ? widget.data.totalBalance : widget.memberData.totalBalance;

  String get _heroSubtitle => _isInvestor
      ? 'Simpanan dan dana siap investasi'
      : 'Simpanan anggota dalam satu ringkasan';

  String get _profileLabel =>
      _isInvestor ? 'Profil investor' : 'Profil anggota';

  List<_HeroBalancePanelData> get _heroPanels => _isInvestor
      ? [
          _HeroBalancePanelData(
            label: 'Simpanan Sukarela',
            amount: widget.data.voluntarySavings,
          ),
          _HeroBalancePanelData(
            label: 'Buy Power',
            amount: widget.data.buyPower,
          ),
        ]
      : [
          _HeroBalancePanelData(
            label: 'Simpanan Sukarela',
            amount: widget.memberData.voluntarySavings,
          ),
          _HeroBalancePanelData(
            label: 'Simpanan Wajib',
            amount: widget.memberData.mandatorySavings,
          ),
        ];

  List<_QuickActionData> get _quickActions => _isInvestor
      ? const [
          _QuickActionData('Top Up', Icons.add_rounded),
          _QuickActionData('Withdraw', Icons.arrow_downward_rounded),
          _QuickActionData('Pinjam', Icons.account_balance_outlined),
          _QuickActionData('Mutasi', Icons.swap_horiz_rounded),
        ]
      : const [
          _QuickActionData('Top Up', Icons.add_rounded),
          _QuickActionData('Withdraw', Icons.arrow_downward_rounded),
          _QuickActionData('Pinjam', Icons.account_balance_outlined),
        ];

  List<_NavDestinationData> get _navDestinations => _isInvestor
      ? const [
          _NavDestinationData('Beranda', Icons.home_rounded),
          _NavDestinationData(
            'Simpanan',
            Icons.account_balance_wallet_outlined,
          ),
          _NavDestinationData('Investasi', Icons.show_chart_rounded),
          _NavDestinationData('Multiguna', Icons.account_balance_outlined),
          _NavDestinationData('Profil', Icons.person_outline_rounded),
        ]
      : const [
          _NavDestinationData('Beranda', Icons.home_rounded),
          _NavDestinationData(
            'Simpanan',
            Icons.account_balance_wallet_outlined,
          ),
          _NavDestinationData('Multiguna', Icons.account_balance_outlined),
          _NavDestinationData('Profil', Icons.person_outline_rounded),
        ];

  String _money(int value) {
    final digits = value.toString();
    final result = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
      result.write(digits[index]);
    }
    return 'Rp $result';
  }

  String _sensitiveMoney(int value) =>
      _balanceVisible ? _money(value) : 'Rp ••••••';

  @override
  void initState() {
    super.initState();
    _currentTime = (widget.now ?? DateTime.now)();
    if (widget.now == null) {
      _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() => _currentTime = DateTime.now());
      });
    }
  }

  @override
  void didUpdateWidget(covariant InvestorHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audience != widget.audience) {
      _previewAudience = widget.audience;
    }
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature sedang disiapkan.')));
  }

  Future<void> _openProfile() async {
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _memberName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _profileLabel,
                style: const TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari akun'),
              ),
            ],
          ),
        ),
      ),
    );
    if (shouldLogout == true) await _logout();
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginPage(auth: _auth)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.loginCanvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: const _HomeScrollBehavior(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final hero = _BalanceHero(
                    memberName: _memberName,
                    greeting: _greeting,
                    avatarUrl: _avatarUrl,
                    totalBalance: _totalBalance,
                    subtitle: _heroSubtitle,
                    panels: _heroPanels,
                    balanceVisible: _balanceVisible,
                    money: _sensitiveMoney,
                    onToggleBalance: () =>
                        setState(() => _balanceVisible = !_balanceVisible),
                    onNotifications: () =>
                        _showComingSoon('Halaman notifikasi'),
                  );
                  final content = Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 132),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AudiencePreviewToggle(
                              audience: _previewAudience,
                              onChanged: (audience) =>
                                  setState(() => _previewAudience = audience),
                            ),
                            const SizedBox(height: 18),
                            const _SectionTitle(title: 'Aksi cepat'),
                            const SizedBox(height: 12),
                            _QuickActions(
                              actions: _quickActions,
                              onTap: _showComingSoon,
                            ),
                            const SizedBox(height: 24),
                            if (_isInvestor) ...[
                              _InvestmentOverview(
                                data: widget.data,
                                money: _sensitiveMoney,
                                onOpen: () => _showComingSoon('Investasi'),
                              ),
                              const SizedBox(height: 30),
                            ],
                            _MultigunaOverview(
                              nextInstallment: _isInvestor
                                  ? widget.data.nextInstallment
                                  : widget.memberData.nextInstallment,
                              installmentDueDate: _isInvestor
                                  ? widget.data.installmentDueDate
                                  : widget.memberData.installmentDueDate,
                              remainingInstallment: _isInvestor
                                  ? widget.data.remainingInstallment
                                  : widget.memberData.remainingInstallment,
                              money: _sensitiveMoney,
                              onOpen: () => _showComingSoon('Multiguna'),
                            ),
                            const SizedBox(height: 30),
                            _SectionTitle(
                              title: 'Aktivitas terakhir',
                              action: 'Lihat semua',
                              onAction: () =>
                                  _showComingSoon('Riwayat transaksi'),
                            ),
                            const SizedBox(height: 4),
                            _ActivityList(
                              activities: _isInvestor
                                  ? widget.data.activities
                                  : widget.memberData.activities,
                              money: _sensitiveMoney,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  final textScale =
                      MediaQuery.textScalerOf(context).scale(14) / 14;
                  final pinHero =
                      constraints.maxHeight >= 650 && textScale <= 1.3;
                  if (!pinHero) {
                    return SingleChildScrollView(
                      physics: _homeScrollPhysics,
                      child: Column(children: [hero, content]),
                    );
                  }
                  return Column(
                    children: [
                      hero,
                      Expanded(
                        child: SingleChildScrollView(
                          physics: _homeScrollPhysics,
                          child: content,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 126 + MediaQuery.paddingOf(context).bottom,
            child: const IgnorePointer(child: _BottomGradientScrim()),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 10,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _isInvestor ? double.infinity : 320,
                ),
                child: _FloatingNavigation(
                  destinations: _navDestinations,
                  onDestinationSelected: (index, label) {
                    if (label == 'Profil') {
                      _openProfile();
                    } else if (label != 'Beranda') {
                      _showComingSoon(label);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.memberName,
    required this.greeting,
    required this.avatarUrl,
    required this.totalBalance,
    required this.subtitle,
    required this.panels,
    required this.balanceVisible,
    required this.money,
    required this.onToggleBalance,
    required this.onNotifications,
  });

  final String memberName;
  final String greeting;
  final String? avatarUrl;
  final int totalBalance;
  final String subtitle;
  final List<_HeroBalancePanelData> panels;
  final bool balanceVisible;
  final String Function(int) money;
  final VoidCallback onToggleBalance;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final stackPanels = MediaQuery.textScalerOf(context).scale(14) > 18;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF003F42),
              Color(0xFF006A66),
              Color(0xFF08A39E),
              AppTheme.mint,
            ],
            stops: [0, 0.5, 0.8, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -90,
              top: -110,
              child: _HeroGlow(
                size: 280,
                colors: [Color(0x80A4EDD2), Color(0x00A4EDD2)],
              ),
            ),
            const Positioned(
              left: -120,
              bottom: -120,
              child: _HeroGlow(
                size: 300,
                colors: [Color(0x7000383D), Color(0x0000383D)],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, topInset + 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MemberHeader(
                        memberName: memberName,
                        greeting: greeting,
                        avatarUrl: avatarUrl,
                        onNotifications: onNotifications,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Total Saldo',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: balanceVisible
                                  ? 'Total saldo ${money(totalBalance)}'
                                  : 'Total saldo disembunyikan',
                              child: ExcludeSemantics(
                                child: Text(
                                  money(totalBalance),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: balanceVisible
                                ? 'Sembunyikan saldo'
                                : 'Tampilkan saldo',
                            onPressed: onToggleBalance,
                            icon: Icon(
                              balanceVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (stackPanels)
                        Column(
                          children: [
                            _FrostedBalancePanel(
                              label: panels.first.label,
                              amount: money(panels.first.amount),
                            ),
                            const SizedBox(height: 8),
                            _FrostedBalancePanel(
                              label: panels.last.label,
                              amount: money(panels.last.amount),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _FrostedBalancePanel(
                                label: panels.first.label,
                                amount: money(panels.first.amount),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _FrostedBalancePanel(
                                label: panels.last.label,
                                amount: money(panels.last.amount),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
      child: SizedBox.square(dimension: size),
    ),
  );
}

class _MemberHeader extends StatelessWidget {
  const _MemberHeader({
    required this.memberName,
    required this.greeting,
    required this.avatarUrl,
    required this.onNotifications,
  });

  final String memberName;
  final String greeting;
  final String? avatarUrl;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Semantics(
        label: 'Foto profil $memberName',
        image: true,
        child: ClipOval(
          child: SizedBox.square(
            dimension: 46,
            child: avatarUrl == null
                ? _AvatarFallback(memberName: memberName)
                : Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) =>
                        _AvatarFallback(memberName: memberName),
                  ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
            ),
            Text(
              memberName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Stack(
        clipBehavior: Clip.none,
        children: [
          _GlassIconButton(
            tooltip: 'Notifikasi, satu belum dibaca',
            icon: Icons.notifications_none_rounded,
            onPressed: onNotifications,
          ),
          const Positioned(
            right: 4,
            top: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.mint,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 8),
            ),
          ),
        ],
      ),
    ],
  );
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.memberName});

  final String memberName;

  @override
  Widget build(BuildContext context) {
    final initials = memberName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return ColoredBox(
      color: const Color(0xFFD5F3E9),
      child: Center(
        child: Text(
          initials.isEmpty ? 'B' : initials,
          style: const TextStyle(
            color: AppTheme.teal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    ),
  );
}

class _FrostedBalancePanel extends StatelessWidget {
  const _FrostedBalancePanel({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33002F32),
          offset: Offset(0, 7),
          blurRadius: 16,
        ),
        BoxShadow(
          color: Color(0x24FFFFFF),
          offset: Offset(-2, -2),
          blurRadius: 8,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.action,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
  });

  final String title;
  final String? action;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(action!, style: const TextStyle(fontSize: 12)),
        )
      else if (actionIcon != null)
        IconButton(
          tooltip: actionTooltip,
          onPressed: onAction,
          icon: Icon(actionIcon, size: 21, color: AppTheme.teal),
        ),
    ],
  );
}

class _AudiencePreviewToggle extends StatelessWidget {
  const _AudiencePreviewToggle({
    required this.audience,
    required this.onChanged,
  });

  final HomeAudience audience;
  final ValueChanged<HomeAudience> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1ECE8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1017324A),
          offset: Offset(0, 5),
          blurRadius: 15,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _AudiencePreviewOption(
              label: 'Investor',
              selected: audience == HomeAudience.investor,
              onTap: () => onChanged(HomeAudience.investor),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _AudiencePreviewOption(
              label: 'Non-investor',
              selected: audience == HomeAudience.member,
              onTap: () => onChanged(HomeAudience.member),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AudiencePreviewOption extends StatelessWidget {
  const _AudiencePreviewOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Preview $label',
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppTheme.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.actions, required this.onTap});

  final List<_QuickActionData> actions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final useTwoColumns =
          constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(12) > 15;
      final columns = useTwoColumns ? 2 : actions.length;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final item in actions)
            SizedBox(
              width: width,
              height: useTwoColumns ? 88 : 78,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1717324A),
                      offset: Offset(0, 5),
                      blurRadius: 13,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF6FCFA), Color(0xFFDDF6ED)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFFFFF)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onTap(item.label),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 22, color: AppTheme.teal),
                          const SizedBox(height: 8),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _InvestmentOverview extends StatelessWidget {
  const _InvestmentOverview({
    required this.data,
    required this.money,
    required this.onOpen,
  });

  final InvestorHomeData data;
  final String Function(int) money;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionTitle(
        title: 'Investasi Anda',
        actionIcon: Icons.north_east_rounded,
        actionTooltip: 'Buka investasi',
        onAction: onOpen,
      ),
      const SizedBox(height: 4),
      const Text(
        'Dana diinvestasikan',
        style: TextStyle(fontSize: 12, color: AppTheme.muted),
      ),
      const SizedBox(height: 4),
      Text(
        money(data.investedFunds),
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(18) > 22;
          final metrics = [
            _ProfitMetric(
              label: 'Profit bulan ini',
              value: '+${money(data.monthlyProfit)}',
            ),
            _ProfitMetric(
              label: 'Akumulasi profit',
              value: '+${money(data.accumulatedProfit)}',
            ),
          ];
          return stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    metrics.first,
                    const SizedBox(height: 12),
                    metrics.last,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: metrics.first),
                    const SizedBox(width: 16),
                    Expanded(child: metrics.last),
                  ],
                );
        },
      ),
      const SizedBox(height: 10),
      Text(
        data.profitPeriod,
        style: const TextStyle(fontSize: 12, color: AppTheme.muted),
      ),
    ],
  );
}

class _ProfitMetric extends StatelessWidget {
  const _ProfitMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppTheme.teal,
        ),
      ),
    ],
  );
}

class _MultigunaOverview extends StatelessWidget {
  const _MultigunaOverview({
    required this.nextInstallment,
    required this.installmentDueDate,
    required this.remainingInstallment,
    required this.money,
    required this.onOpen,
  });

  final int nextInstallment;
  final String installmentDueDate;
  final int remainingInstallment;
  final String Function(int) money;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionTitle(
        title: 'Multiguna',
        action: 'Lihat jadwal',
        onAction: onOpen,
      ),
      const SizedBox(height: 10),
      Material(
        color: const Color(0xFFEDF7F5),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFFFFF)),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.teal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cicilan berikutnya',
                        style: TextStyle(fontSize: 12, color: AppTheme.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        money(nextInstallment),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$installmentDueDate - Sisa ${money(remainingInstallment)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.teal),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activities, required this.money});

  final List<InvestorHomeActivity> activities;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < activities.length; index++) ...[
        _ActivityRow(activity: activities[index], money: money),
        if (index != activities.length - 1)
          const Divider(height: 1, indent: 52),
      ],
    ],
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.money});

  final InvestorHomeActivity activity;
  final String Function(int) money;

  String get _prefix => switch (activity.direction) {
    HomeActivityDirection.incoming => '+',
    HomeActivityDirection.outgoing => '-',
    HomeActivityDirection.transfer => '',
  };

  IconData get _icon => switch (activity.direction) {
    HomeActivityDirection.incoming => Icons.south_west_rounded,
    HomeActivityDirection.outgoing => Icons.north_east_rounded,
    HomeActivityDirection.transfer => Icons.swap_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final amount = Text(
          '$_prefix${money(activity.amount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: activity.direction == HomeActivityDirection.incoming
                ? AppTheme.teal
                : AppTheme.ink,
          ),
        );
        final details = Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEDF7F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox.square(
                dimension: 40,
                child: Icon(_icon, size: 21, color: AppTheme.teal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    activity.date,
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        );
        final compact =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(13) > 16;
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: amount),
                ],
              )
            : Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 8),
                  amount,
                ],
              );
      },
    ),
  );
}

class _BottomGradientScrim extends StatelessWidget {
  const _BottomGradientScrim();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00FBFDFC), Color(0x99FBFDFC), AppTheme.loginCanvas],
        stops: [0, 0.56, 1],
      ),
    ),
  );
}

class _FloatingNavigation extends StatelessWidget {
  const _FloatingNavigation({
    required this.destinations,
    required this.onDestinationSelected,
  });

  final List<_NavDestinationData> destinations;
  final void Function(int index, String label) onDestinationSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: ValueKey('home-floating-nav-${destinations.length}'),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F006A66),
          offset: Offset(0, 8),
          blurRadius: 26,
        ),
        BoxShadow(
          color: Color(0x0F17324A),
          offset: Offset(0, 2),
          blurRadius: 8,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (var index = 0; index < destinations.length; index++)
            Expanded(
              flex: index == 0 ? 2 : 1,
              child: _NavigationItem(
                selected: index == 0,
                label: destinations[index].label,
                icon: destinations[index].icon,
                onTap: () =>
                    onDestinationSelected(index, destinations[index].label),
              ),
            ),
        ],
      ),
    ),
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF004E50),
                      Color(0xFF006A66),
                      Color(0xFF008579),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppTheme.muted,
              ),
              if (selected) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
