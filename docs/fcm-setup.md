# Firebase Cloud Messaging

Targets: Android (`id.basyainvestama.app`) and web/PWA, Firebase project
`basya-investama`. The public VAPID key is in
`lib/core/notifications/fcm_registration.dart`.

After successful login/profile loading or session restoration, MainContainer
starts FcmRegistration. Android requests notification permission. Web presents an
activation button so the browser permission request originates from a user click.
Previously granted permission allows automatic registration on subsequent logins.

The client sends `PUT https://api.basyainvestama.id/app/profile/fcm-token`,
with the session Authorization header and JSON `{"fcm_token":"..."}`.
Registration failure does not block authentication. It retries up to three times
with increasing delay, and again on app resume. Token refresh also triggers sync.
Expired sessions do not send requests. Tokens and credentials are not logged.

## Deployment and manual checks

- Serve PWA over HTTPS (localhost is suitable for development).
- Serve `/firebase-messaging-sw.js` as JavaScript at the domain root, even when
  Flutter is hosted under a subpath. Do not rewrite it to index.html.
- Keep service-worker Firebase configuration aligned with firebase_options.dart
  and its JS SDK version aligned with firebase_core_web (currently 12.19.0).
- Backend CORS must permit the PWA origin, PUT and OPTIONS, and Authorization and
  Content-Type headers.
- Android: log in on a device with Google Play services and grant permission.
- Web: log in, click Aktifkan notifikasi, and grant browser permission. In DevTools
  verify the service worker and the authenticated PUT response. Do not share tokens.
- Test a notification payload from Firebase Console/backend with the app in the
  background, then test login with permission denied and with network failure.
- Reopen a stored session and verify token registration occurs again.

## Remaining scope

Live device delivery and backend acceptance require manual validation. Foreground
notification banners and notification-tap navigation are not implemented.
Logout sends `{"fcm_token":null}` to the same endpoint with the current session's
Authorization header before clearing local credentials/session. Registration and
removal share a queue: removal follows an in-flight registration and blocks late
updates from that session. If removal fails, logout retains the session and shows
the existing retry message. No pending notification already sent can be recalled.
Backend multi-device token storage behavior is also not specified.
