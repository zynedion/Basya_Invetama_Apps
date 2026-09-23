import 'dart:js_interop';

@JS('basyaShowNotification')
external JSPromise<JSAny?> _show(JSString title, JSString body, JSString id);

Future<void> showSystemNotification(
  String title,
  String body,
  String? id,
) async {
  await _show(title.toJS, body.toJS, (id ?? '').toJS).toDart;
}
