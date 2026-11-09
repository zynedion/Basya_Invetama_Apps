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
    if (kDebugMode) {
      debugPrint(
        '[FCM][_start] Invoked; session=${widget.session != null}, appsCount=${Firebase.apps.length}, kIsWeb=$kIsWeb',
      );
    }
    if (widget.session == null) {
      if (kDebugMode) {
        debugPrint('[FCM][_start] Aborted: widget.session is null');
      }
      return;
    }
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[FCM][_start] Aborted: Firebase.apps is empty! Firebase.initializeApp was not completed.',
        );
      }
      return;
    }
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      if (kDebugMode) {
        debugPrint(
          '[FCM][_start] Aborted: platform is not Web or Android ($defaultTargetPlatform)',
        );
      }
      return;
    }
    try {
      final supported = await FirebaseMessaging.instance.isSupported();
      if (kDebugMode) {
        debugPrint(
          '[FCM][_start] FirebaseMessaging.isSupported() = $supported',
        );
      }
      if (!supported || !mounted) return;
      _messaging = FirebaseMessaging.instance;
      _refresh = _messaging!.onTokenRefresh.listen(
        (newToken) {
          if (kDebugMode) {
            debugPrint('[FCM] onTokenRefresh triggered');
          }
          unawaited(_sync());
        },
        onError: (Object err) {
          if (kDebugMode) {
            debugPrint('[FCM] onTokenRefresh error: ${err.runtimeType}');
          }
          _scheduleRetry();
        },
      );
      if (!kIsWeb) {
        if (kDebugMode) {
          debugPrint('[FCM][_start] Requesting native permission...');
        }
        await _messaging!.requestPermission();
      }
      if (kDebugMode) {
        debugPrint('[FCM][_start] Triggering initial _sync()...');
      }
      await _sync();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM][_start] Exception in _start: ${e.runtimeType}');
      }
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (!mounted || widget.session == null || widget.session!.isExpired) {
      if (kDebugMode) {
        debugPrint(
          '[FCM][_scheduleRetry] Skip retry: mounted=$mounted, session=${widget.session != null}',
        );
      }
      return;
    }
    if (_failures >= 3) {
      if (kDebugMode) {
        debugPrint('[FCM][_scheduleRetry] Max failures reached ($_failures)');
      }
      return;
    }
    _failures++;
    final delay = Duration(seconds: 10 * _failures);
    if (kDebugMode) {
      debugPrint(
        '[FCM][_scheduleRetry] Retrying in ${delay.inSeconds} seconds (attempt $_failures)...',
      );
    }
    _retry?.cancel();
    _retry = Timer(delay, () {
      if (kDebugMode) {
        debugPrint('[FCM][_scheduleRetry] Retry timer fired');
      }
      unawaited(_messaging == null ? _start() : _sync());
    });
  }

  Future<void> _sync() async {
    final messaging = _messaging;
    final session = widget.session;
    if (kDebugMode) {
      debugPrint(
        '[FCM][_sync] Invoked: mounted=$mounted, busy=$_busy, messaging=${messaging != null}, session=${session != null}',
      );
    }
    if (!mounted ||
        _busy ||
        messaging == null ||
        session == null ||
        session.isExpired) {
      if (kDebugMode) {
        debugPrint('[FCM][_sync] Exited early (guard condition).');
      }
      return;
    }
    _busy = true;
    try {
      final settings = await messaging.getNotificationSettings();
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[FCM] Notification authorizationStatus: ${settings.authorizationStatus}',
        );
      }
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      setState(
        () => _offerPermission =
            kIsWeb &&
            settings.authorizationStatus == AuthorizationStatus.notDetermined,
      );
      if (kDebugMode) {
        debugPrint(
          '[FCM][_sync] allowed=$allowed, offerPermission=$_offerPermission',
        );
      }
      if (!allowed) {
        if (kDebugMode) {
          debugPrint(
            '[FCM] Notification permission not granted (${settings.authorizationStatus}). Skipping token sync.',
          );
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('[FCM][_sync] Calling messaging.getToken()...');
      }
      final token = await messaging.getToken(
        vapidKey: kIsWeb ? _vapidKey : null,
      );
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[FCM] Failed to get FCM token (null or empty). Scheduling retry...',
          );
        }
        _scheduleRetry();
        return;
      }
      if (kDebugMode) {
        debugPrint('[FCM] FCM token obtained');
      }
      if (token == _sentToken) {
        if (kDebugMode) {
          debugPrint(
            '[FCM] Token unchanged from previous sync. Skipping send.',
          );
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('[FCM] Triggering token update to backend...');
      }
      await _api.update(session, token);
      _sentToken = token;
      _failures = 0;
      _retry?.cancel();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Error in token sync: ${e.runtimeType}');
      }
      _scheduleRetry();
    } finally {
      _busy = false;
    }
  }

  Future<void> _enable() async {
    if (kDebugMode) {
      debugPrint('[FCM][_enable] User clicked enable notification button');
    }
    try {
      // Call directly from the click to preserve browser user activation.
      final result = await _messaging?.requestPermission();
      if (kDebugMode) {
        debugPrint(
          '[FCM][_enable] requestPermission result: ${result?.authorizationStatus}',
        );
      }
      await _sync();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM][_enable] requestPermission error: ${e.runtimeType}');
      }
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
