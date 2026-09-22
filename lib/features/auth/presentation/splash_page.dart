import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../data/auth_service.dart';
import '../domain/auth_gateway.dart';
import '../domain/auth_profile.dart';
import '../domain/auth_session.dart';
import 'login_page.dart';
import '../../home/presentation/investor_home_page.dart';
import '../../home/data/home_summary_api_client.dart';
import '../../home/domain/home_summary_gateway.dart';
import '../../navigation/presentation/main_container.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.auth,
    this.summaryGateway,
    this.animateLoginBackground = true,
  });

  final AuthGateway? auth;
  final HomeSummaryGateway? summaryGateway;
  final bool animateLoginBackground;
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final AuthGateway _auth = widget.auth ?? AuthService();
  late final HomeSummaryGateway? _summaryGateway =
      widget.summaryGateway ??
      (widget.auth == null ? HomeSummaryApiClient() : null);
  late final Future<({AuthSession session, AuthProfile profile})?> _session;
  Timer? _fallback;
  bool _leaving = false;
  bool _showSplash = false;
  @override
  void initState() {
    super.initState();
    _session = _restoreSessionWithProfile();
    _animation = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _openLogin();
      });
    _session.then((restored) {
      if (mounted && !_showSplash) _openLogin();
    });
  }

  void _startSplash() {
    if (!mounted || _showSplash) return;
    setState(() => _showSplash = true);
    _fallback = Timer(const Duration(seconds: 8), _openLogin);
  }

  Future<({AuthSession session, AuthProfile profile})?>
  _restoreSessionWithProfile() async {
    try {
      final activeSession = await _auth.readActiveSession();
      if (activeSession == null) _startSplash();
      final session = activeSession ?? await _auth.restoreSession();
      if (session == null) return null;
      final profile = await _auth.getProfile(session);
      return (session: session, profile: profile);
    } catch (_) {
      _startSplash();
      return null;
    }
  }

  Future<void> _openLogin() async {
    if (!mounted || _leaving) return;
    _leaving = true;
    _fallback?.cancel();
    final restored = await _session;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => restored == null
            ? LoginPage(
                auth: _auth,
                summaryGateway: _summaryGateway,
                animateBackground: widget.animateLoginBackground,
              )
            : MainContainer(
                auth: _auth,
                profile: restored.profile,
                session: restored.session,
                summaryGateway: _summaryGateway,
                audience: restored.profile.usesInvestorHome
                    ? HomeAudience.investor
                    : HomeAudience.member,
              ),
      ),
    );
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: !_showSplash
        ? const SizedBox.expand()
        : Center(
            child: Semantics(
              label: 'Basya Investama',
              image: true,
              child: Lottie.asset(
                'assets/animation/Scene-3-no-watermark.json',
                controller: _animation,
                fit: BoxFit.contain,
                repeat: false,
                onLoaded: (composition) {
                  if (!mounted || _leaving) return;
                  _animation.duration = composition.duration;
                  _animation.forward();
                },
                errorBuilder: (_, error, stackTrace) =>
                    Image.asset('assets/logo/basya-favicon.png', width: 96),
              ),
            ),
          ),
  );
}
