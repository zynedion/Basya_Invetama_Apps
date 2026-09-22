import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../features/auth/domain/auth_session.dart';
import 'fcm_token_api.dart';

/// Lives only inside an authenticated screen; never delays authentication.
class FcmRegistration extends StatefulWidget {
  const FcmRegistration({
    super.key,
    required this.session,
    required this.child,
  });
  final AuthSession? session;
  final Widget child;

  @override
  State<FcmRegistration> createState() => _FcmRegistrationState();
}

class _FcmRegistrationState extends State<FcmRegistration>
    with WidgetsBindingObserver {
  static const _vapidKey =
      'BGcB4oqaZNl6KrjLeVXh_GMaix3V73IsQsPxey8ggfIx89dUw32YXT_EQi18wizV8A-jZKBiPZkQkrW5K7WsYdI';
  final _api = FcmTokenApi.shared;
  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _refresh;
  Timer? _retry;
  String? _sentToken;
  bool _offerPermission = false;
  bool _busy = false;
  int _failures = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  Future<void> _start() async {
    if (widget.session == null ||
        Firebase.apps.isEmpty ||
        (!kIsWeb && defaultTargetPlatform != TargetPlatform.android)) {
      return;
    }
    try {
      if (!await FirebaseMessaging.instance.isSupported() || !mounted) return;
      _messaging = FirebaseMessaging.instance;
      _refresh = _messaging!.onTokenRefresh.listen(
        (_) => unawaited(_sync()),
        onError: (Object _) => _scheduleRetry(),
      );
      if (!kIsWeb) await _messaging!.requestPermission();
      await _sync();
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (!mounted || widget.session == null || widget.session!.isExpired) return;
    // Bounded retries; resuming the app also retries registration.
    if (_failures >= 3) return;
    _failures++;
    _retry?.cancel();
    _retry = Timer(Duration(seconds: 10 * _failures), () {
      unawaited(_messaging == null ? _start() : _sync());
    });
  }

  Future<void> _sync() async {
    final messaging = _messaging;
    final session = widget.session;
    if (!mounted ||
        _busy ||
        messaging == null ||
        session == null ||
        session.isExpired) {
      return;
    }
    _busy = true;
    try {
      final settings = await messaging.getNotificationSettings();
      if (!mounted) return;
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      setState(
        () => _offerPermission =
            kIsWeb &&
            settings.authorizationStatus == AuthorizationStatus.notDetermined,
      );
      if (!allowed) return;
      final token = await messaging.getToken(
        vapidKey: kIsWeb ? _vapidKey : null,
      );
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        _scheduleRetry();
        return;
      }
      if (token == _sentToken) return;
      await _api.update(session, token);
      _sentToken = token;
      _failures = 0;
      _retry?.cancel();
    } catch (_) {
      _scheduleRetry();
    } finally {
      _busy = false;
    }
  }

  Future<void> _enable() async {
    try {
      // Call directly from the click to preserve browser user activation.
      await _messaging?.requestPermission();
      await _sync();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifikasi belum dapat diaktifkan. Periksa izin browser.',
            ),
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _failures = 0;
      unawaited(_messaging == null ? _start() : _sync());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retry?.cancel();
    unawaited(_refresh?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_offerPermission)
        SafeArea(
          bottom: false,
          child: MaterialBanner(
            content: const Text(
              'Aktifkan notifikasi untuk menerima kabar akun Anda.',
            ),
            actions: [
              TextButton(
                onPressed: _enable,
                child: const Text('Aktifkan notifikasi'),
              ),
            ],
          ),
        ),
      Expanded(child: widget.child),
    ],
  );
}
