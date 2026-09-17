import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_gateway.dart';
import '../../auth/domain/auth_profile.dart';
import '../../auth/domain/auth_session.dart';
import '../../home/domain/home_summary_gateway.dart';
import '../../home/presentation/investor_home_page.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({
    super.key,
    this.auth,
    this.profile,
    this.session,
    this.summaryGateway,
    this.audience = HomeAudience.investor,
  });

  final AuthGateway? auth;
  final AuthProfile? profile;
  final AuthSession? session;
  final HomeSummaryGateway? summaryGateway;
  final HomeAudience audience;

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  late HomeAudience _audience = widget.audience;
  int _selectedIndex = 0;

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
    setState(() {
      _audience = audience;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final pages = [
      InvestorHomePage(
        auth: widget.auth,
        profile: widget.profile,
        session: widget.session,
        summaryGateway: widget.summaryGateway,
        audience: _audience,
        onAudienceChanged: _changeAudience,
      ),
      for (final destination in destinations.skip(1))
        _EmptyFeaturePage(
          key: ValueKey('empty-${destination.label.toLowerCase()}'),
          destination: destination,
        ),
    ];
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.loginCanvas,
      body: Stack(
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
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainDestination {
  const _MainDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _EmptyFeaturePage extends StatelessWidget {
  const _EmptyFeaturePage({super.key, required this.destination});

  final _MainDestination destination;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 112),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFEDF7F5),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 72,
                child: Icon(destination.icon, color: AppTheme.teal, size: 30),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              destination.label,
              key: ValueKey('page-title-${destination.label.toLowerCase()}'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Halaman ini siap dikembangkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      ),
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
