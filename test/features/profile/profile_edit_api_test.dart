import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/forms/presentation/form_widgets.dart';
import 'package:basya_investama/features/profile/data/profile_edit_api.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2030),
  );
  test('options preserves bank IDs and leading zero account numbers', () async {
    final api = ProfileEditApi(
      client: MockClient((r) async {
        expect(r.url.path, '/app/profile/edit/options');
        expect(r.headers['Authorization'], 'Bearer test');
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'profile': {
                'bank_account': {'bank_id': 12, 'account_no': '00123'},
              },
              'bank_options': [
                {'id': 12, 'name': 'Bank'},
              ],
            },
          }),
          200,
        );
      }),
    );
    final result = await api.options(session);
    expect(result['profile']['bank_account']['account_no'], '00123');
    api.dispose();
  });
  for (final photo in [false, true]) {
    test('multipart profile save photo=$photo', () async {
      var calls = 0;
      final api = ProfileEditApi(
        client: MockClient((r) async {
          calls++;
          expect(r.url.path, '/app/profile');
          expect(r.method, 'POST');
          final body = latin1.decode(r.bodyBytes);
          expect(body, contains('name="bank_id"\r\n\r\n12'));
          expect(body, contains('name="norek"\r\n\r\n00123'));
          expect(body.contains('name="foto_user"'), photo);
          expect(body, isNot(contains('user_id')));
          return http.Response(
            '{"status":true,"data":{"profile":{},"bank_change":{"effective_immediately":true}}}',
            200,
          );
        }),
      );
      await api.save(
        session,
        {
          'full_name': 'Test',
          'email': 'test@example.com',
          'contact': '08123456789',
          'address': 'Alamat',
          'bank_id': '12',
          'account_name': 'Test',
          'norek': '00123',
        },
        photo
            ? LocalAttachment(
                name: 'photo.png',
                bytes: Uint8List.fromList([1, 2]),
                isImage: true,
              )
            : null,
      );
      expect(calls, 1);
      api.dispose();
    });
  }
  test('server rejection is not replayed', () async {
    var calls = 0;
    final api = ProfileEditApi(
      client: MockClient((r) async {
        calls++;
        return http.Response(
          '{"status":false,"message":"Email telah digunakan"}',
          422,
        );
      }),
    );
    await expectLater(
      api.save(session, {}, null),
      throwsA(isA<ProfileEditFailure>()),
    );
    expect(calls, 1);
    api.dispose();
  });
}
