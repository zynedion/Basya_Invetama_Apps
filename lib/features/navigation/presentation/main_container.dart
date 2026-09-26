import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/last_destination_store.dart';
import '../../../core/notifications/fcm_registration.dart';

import '../../../core/theme/app_theme.dart';
import '../../forms/presentation/form_routes.dart';
import '../../auth/domain/auth_gateway.dart';
import '../../auth/domain/auth_profile.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/login_page.dart';
import '../../home/domain/home_summary_gateway.dart';
import '../../home/presentation/investor_home_page.dart';
import '../../investment/presentation/investment_page.dart';
import '../../multiguna/data/multiguna_api_client.dart';
import '../../multiguna/domain/multiguna_gateway.dart';
import '../../multiguna/domain/multiguna_overview_data.dart';
import '../../multiguna/presentation/multiguna_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../savings/presentation/savings_page.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({
    super.key,
    this.auth,
    this.profile,
    this.session,
    this.summaryGateway,
    this.multigunaGateway,
    this.audience = HomeAudience.investor,
  });

  final AuthGateway? auth;
  final AuthProfile? profile;
  final AuthSession? session;
  final HomeSummaryGateway? summaryGateway;
  final MultigunaGateway? multigunaGateway;
  final HomeAudience audience;

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  late HomeAudience _audience = widget.audience;
  int _selectedIndex = 0;
  final _lastDestination = LastDestinationStore();
  bool _destinationChanged = false;
  bool _backgrounding = false;
  static const _lifecycle = MethodChannel('basya/app_lifecycle');
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool _loggingOut = false;
  MultigunaGateway? _multigunaGateway;
  MultigunaOverviewData? _multigunaData;
  bool _multigunaLoading = false;
  String? _multigunaError;

  @override
  void initState() {
    super.initState();
    _restoreDestination();
    _multigunaGateway =
        widget.multigunaGateway ??
        (widget.session == null ? null : MultigunaApiClient());
    if (_multigunaGateway == null || widget.session == null) {
      _multigunaData = MultigunaOverviewData.demo;
    } else {
      _loadMultiguna();
    }
  }

  Future<void> _loadMultiguna() async {
    final gateway = _multigunaGateway;
    final session = widget.session;
    if (gateway == null || session == null) return;
    setState(() {
      _multigunaLoading = true;
      _multigunaError = null;
    });
    try {
      final data = await gateway.getOverview(session);
      if (!mounted) return;
      setState(() {
        _multigunaData = data;
        _multigunaLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _multigunaData = null;
        _multigunaLoading = false;
        _multigunaError = 'Data Multiguna belum dapat dimuat.';
      });
    }
  }

  Future<void> _restoreDestination() async {
    final userId = widget.profile?.id;
    if (userId == null) return;
    final destination = await _lastDestination.read(userId);
    if (!mounted || _destinationChanged) return;
    final index = _destinations.indexWhere((item) => item.label == destination);
    if (index >= 0) setState(() => _selectedIndex = index);
  }

  void _selectDestination(int index) {
    _destinationChanged = true;
    setState(() => _selectedIndex = index);
    final userId = widget.profile?.id;
    if (userId != null) {
      _lastDestination.save(userId, _destinations[index].label);
    }
  }

  Future<void> _moveToBackground() async {
    if (_backgrounding) return;
    _backgrounding = true;
    try {
      final moved = await _lifecycle.invokeMethod<bool>('moveToBackground');
      if (moved != true) throw PlatformException(code: 'background_failed');
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Belum dapat meminimalkan aplikasi. Silakan coba lagi.',
            ),
          ),
        );
      }
    } finally {
      _backgrounding = false;
    }
  }

  List<_MainDestination> get _destinations => _audience == HomeAudience.investor
      ? const [
          _MainDestination('Beranda', Icons.home_rounded),
          _MainDestination('Simpanan', Icons.account_balance_wallet_outlined),
          _MainDestination('Investasi', Icons.show_chart_rounded),
          _MainDestination('Multiguna', Icons.account_balance_outlined),
          _MainDestination('Profil', Icons.person_outline_rounded),
        ]
      : const [
          _MainDestination('Beranda', Icons.home_rounded),
          _MainDestination('Simpanan', Icons.account_balance_wallet_outlined),
          _MainDestination('Multiguna', Icons.account_balance_outlined),
          _MainDestination('Profil', Icons.person_outline_rounded),
        ];

  void _changeAudience(HomeAudience audience) {
    _destinationChanged = true;
    setState(() {
      _audience = audience;
      _selectedIndex = 0;
    });
  }

  Future<void> _logout() async {
    final auth = widget.auth;
    print(
      '[AUTH][logout] Button pressed; authAvailable=${auth != null}; busy=$_loggingOut',
    );
    if (auth == null || _loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await auth.logout();
      await _lastDestination.clear();
      print('[AUTH][logout] Opening login');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) =>
              LoginPage(auth: auth, summaryGateway: widget.summaryGateway),
        ),
        (_) => false,
      );
    } catch (error) {
      print('[AUTH][logout] Failed: ${error.runtimeType}');
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Belum dapat keluar. Silakan coba lagi.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final pages = [
      for (final destination in destinations)
        switch (destination.label) {
          'Beranda' => InvestorHomePage(
            auth: widget.auth,
            profile: widget.profile,
            session: widget.session,
            summaryGateway: widget.summaryGateway,
            audience: _audience,
            onAudienceChanged: _changeAudience,
            multigunaData: _multigunaData,
            multigunaResolved: !_multigunaLoading,
            onOpenMultiguna: () {
              final index = destinations.indexWhere(
                (item) => item.label == 'Multiguna',
              );
              if (index >= 0) _selectDestination(index);
            },
          ),
          'Simpanan' => SavingsPage(
            onWithdraw: () => openBasyaForm(
              context,
              BasyaFormKind.withdraw,
              profile: widget.profile,
            ),
          ),
          'Investasi' => const InvestmentPage(),
          'Multiguna' => MultigunaPage(
            data: _multigunaData,
            loading: _multigunaLoading,
            errorMessage: _multigunaError,
            onRetry: _loadMultiguna,
          ),
          'Profil' => ProfilePage(
            profile: widget.profile,
            onLogout: _logout,
            loggingOut: _loggingOut,
            onEditProfile: () => openBasyaForm(
              context,
              BasyaFormKind.editProfile,
              profile: widget.profile,
            ),
            onChangePassword: () =>
                openBasyaForm(context, BasyaFormKind.password),
          ),
          _ => const SizedBox.shrink(),
        },
    ];
    return PopScope<Object?>(
      canPop: !_isAndroid,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isAndroid) _moveToBackground();
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppTheme.loginCanvas,
        body: FcmRegistration(
          session: _loggingOut ? null : widget.session,
          key: ValueKey(_loggingOut),
          child: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(index: _selectedIndex, children: pages),
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
                      maxWidth: _audience == HomeAudience.investor
                          ? double.infinity
                          : 320,
                    ),
                    child: _FloatingNavigation(
                      destinations: destinations,
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _selectDestination,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainDestination {
  const _MainDestination(this.label, this.icon);

  final String label;
  final IconData icon;
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
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<_MainDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const inactiveItemWidth = 48.0;
          final inactiveCount = destinations.length - 1;
          final activeItemWidth =
              constraints.maxWidth - (inactiveItemWidth * inactiveCount);
          final activeLeft = inactiveItemWidth * selectedIndex;

          return SizedBox(
            height: 48,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  left: activeLeft,
                  top: 0,
                  bottom: 0,
                  width: activeItemWidth,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF004E50),
                          Color(0xFF006A66),
                          Color(0xFF008579),
                        ],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(26)),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 560),
                        curve: Curves.easeOutCubic,
                        width: index == selectedIndex
                            ? activeItemWidth
                            : inactiveItemWidth,
                        child: _NavigationItem(
                          selected: index == selectedIndex,
                          label: destinations[index].label,
                          icon: destinations[index].icon,
                          onTap: () => onDestinationSelected(index),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
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
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppTheme.muted,
              ),
              Flexible(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: selected ? 1 : 0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Offstage(
                        offstage: value <= 0.001,
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0).toDouble(),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 7),
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
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
