import 'package:flutter/widgets.dart';

/// Visibility for retained tabs, covered routes, and backgrounded applications.
mixin VisiblePageState<T extends StatefulWidget> on State<T> {
  late final AppLifecycleListener _lifecycle;
  bool pageVisible = false;
  bool _foreground = true;
  bool _tabVisible = false;
  bool _routeVisible = false;
  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabVisible = TickerMode.of(context);
    _routeVisible = ModalRoute.isCurrentOf(context) ?? true;
    _updateVisibility();
  }

  void _onLifecycle(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateVisibility();
  }

  void _updateVisibility() {
    final next = _foreground && _tabVisible && _routeVisible;
    if (next == pageVisible) return;
    pageVisible = next;
    onPageVisibilityChanged(next);
  }

  void onPageVisibilityChanged(bool visible);
  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }
}
