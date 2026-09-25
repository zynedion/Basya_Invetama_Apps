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
    print('[FCM][_start] Invoked; session=${widget.session != null}, appsCount=${Firebase.apps.length}, kIsWeb=$kIsWeb');
    if (widget.session == null) {
      print('[FCM][_start] Aborted: widget.session is null');
      return;
    }
    if (Firebase.apps.isEmpty) {
      print('[FCM][_start] Aborted: Firebase.apps is empty! Firebase.initializeApp was not completed.');
      return;
    }
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      print('[FCM][_start] Aborted: platform is not Web or Android ($defaultTargetPlatform)');
      return;
    }
    try {
      final supported = await FirebaseMessaging.instance.isSupported();
      print('[FCM][_start] FirebaseMessaging.isSupported() = $supported');
      if (!supported || !mounted) return;
      _messaging = FirebaseMessaging.instance;
      _refresh = _messaging!.onTokenRefresh.listen(
        (newToken) {
          print('[FCM] onTokenRefresh triggered: $newToken');
          unawaited(_sync());
        },
        onError: (Object err) {
          print('[FCM] onTokenRefresh error: $err');
          _scheduleRetry();
        },
      );
      if (!kIsWeb) {
        print('[FCM][_start] Requesting native permission...');
        await _messaging!.requestPermission();
      }
      print('[FCM][_start] Triggering initial _sync()...');
      await _sync();
    } catch (e, stack) {
      print('[FCM][_start] Exception in _start: $e\n$stack');
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (!mounted || widget.session == null || widget.session!.isExpired) {
      print('[FCM][_scheduleRetry] Skip retry: mounted=$mounted, session=${widget.session != null}');
      return;
    }
    if (_failures >= 3) {
      print('[FCM][_scheduleRetry] Max failures reached ($_failures)');
      return;
    }
    _failures++;
    final delay = Duration(seconds: 10 * _failures);
    print('[FCM][_scheduleRetry] Retrying in ${delay.inSeconds} seconds (attempt $_failures)...');
    _retry?.cancel();
    _retry = Timer(delay, () {
      print('[FCM][_scheduleRetry] Retry timer fired');
      unawaited(_messaging == null ? _start() : _sync());
    });
  }

  Future<void> _sync() async {
    final messaging = _messaging;
    final session = widget.session;
    print('[FCM][_sync] Invoked: mounted=$mounted, busy=$_busy, messaging=${messaging != null}, session=${session != null}');
    if (!mounted ||
        _busy ||
        messaging == null ||
        session == null ||
        session.isExpired) {
      print('[FCM][_sync] Exited early (guard condition).');
      return;
    }
    _busy = true;
    try {
      final settings = await messaging.getNotificationSettings();
      if (!mounted) return;
      print(
        '[FCM] Notification authorizationStatus: ${settings.authorizationStatus}',
      );
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      setState(
        () => _offerPermission =
            kIsWeb &&
            settings.authorizationStatus == AuthorizationStatus.notDetermined,
      );
      print('[FCM][_sync] allowed=$allowed, offerPermission=$_offerPermission');
      if (!allowed) {
        print('[FCM] Notification permission not granted (${settings.authorizationStatus}). Skipping token sync.');
        return;
      }
      print('[FCM][_sync] Calling messaging.getToken()...');
      final token = await messaging.getToken(
        vapidKey: kIsWeb ? _vapidKey : null,
      );
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        print('[FCM] Failed to get FCM token (null or empty). Scheduling retry...');
        _scheduleRetry();
        return;
      }
      print('[FCM] Got FCM token: $token');
      if (token == _sentToken) {
        print('[FCM] Token unchanged from previous sync. Skipping send.');
        return;
      }
      print('[FCM] Triggering token update to backend...');
      await _api.update(session, token);
      _sentToken = token;
      _failures = 0;
      _retry?.cancel();
    } catch (e, stack) {
      print('[FCM] Error in token sync: $e\n$stack');
      _scheduleRetry();
    } finally {
      _busy = false;
    }
  }

  Future<void> _enable() async {
    print('[FCM][_enable] User clicked enable notification button');
    try {
      // Call directly from the click to preserve browser user activation.
      final result = await _messaging?.requestPermission();
      print('[FCM][_enable] requestPermission result: ${result?.authorizationStatus}');
      await _sync();
    } catch (e, stack) {
      print('[FCM][_enable] requestPermission error: $e\n$stack');
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
