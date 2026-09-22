import 'dart:convert';

import 'package:basya_investama/core/theme/app_theme.dart';
import 'package:basya_investama/features/auth/data/auth_api_client.dart';
import 'package:basya_investama/features/auth/domain/auth_profile.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _user = {
  'id': 25,
  'username': 'member@example.com',
  'full_name': 'Nama Member',
  'email': 'member@example.com',
  'foto_user': 'default.png',
  'group_level': 'member',
  'aktif': 'Y',
};
const _member = {
  'id': 10,
  'id_nasabah': 'N250001',
  'full_name': 'Nama Member',
  'contact': '081234567890',
  'joined_at': '2025-01-11 10:21:13',
  'bank_id': 12,
  'bank_name': 'Nama Bank',
  'norek': '001234567890',
  'account_name': 'Nama Pemilik',
  'kyc_status': 'Y',
  'flag': 'N',
};
const _investor = {
  'id': 4,
  'nasabah_id': 10,
  'reg_id': 'I250001',
  'fullname': 'Nama Investor',
  'kyc_status': 'Y',
  'flag': 'Y',
};

Future<AuthProfile> _fetch({
  Object? member = _member,
  Object? investor = _investor,
}) {
  final api = AuthApiClient(
    client: MockClient(
      (_) async => http.Response(
        jsonEncode({
          'status': true,
          'user': _user,
          'nasabah': member,
          'investor': investor,
        }),
        200,
      ),
    ),
  );
  return api.getProfile(
    AuthSession(
      accessToken: 'test-token',
      tokenType: 'Bearer',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    ),
  );
}

void main() {
  test(
    'Profile maps member and investor fields without substituting user ID',
    () async {
      final profile = await _fetch();
      expect(profile.id, '25');
      expect(profile.nasabah!.id, '10');
      expect(profile.nasabah!.memberNumber, 'N250001');
      expect(profile.nasabah!.contact, '081234567890');
      expect(profile.nasabah!.accountNumber, '001234567890');
      expect(profile.nasabah!.bankId, '12');
      expect(profile.nasabah!.joinedAt, DateTime(2025, 1, 11, 10, 21, 13));
      expect(profile.nasabah!.active, isFalse);
      expect(profile.active, isTrue);
      expect(profile.investor!.registrationNumber, 'I250001');
      expect(profile.investor!.fullName, 'Nama Investor');
      expect(profile.investor!.active, isTrue);
    },
  );

  test('Missing profiles and partial nullable fields remain unknown', () async {
    final absent = await _fetch(member: null, investor: null);
    expect(absent.nasabah, isNull);
    expect(absent.investor, isNull);
    expect(absent.hasInvestorProfile, isFalse);
    final partial = await _fetch(
      member: {'joined_at': 'invalid', 'flag': null},
      investor: null,
    );
    expect(partial.nasabah!.joinedAt, isNull);
    expect(partial.nasabah!.active, isNull);
    expect(partial.nasabah!.accountNumber, isEmpty);
  });

  testWidgets(
    'Profile renders supplied fields without KYC on a narrow screen',
    (tester) async {
      final profile = await _fetch();
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: ProfilePage(profile: profile, onLogout: () {}),
            ),
          ),
        ),
      );
      expect(find.text('N250001'), findsOneWidget);
      expect(find.text('11 Januari 2025'), findsOneWidget);
      expect(find.text('BI-000025'), findsNothing);
      expect(find.text('081234567890'), findsOneWidget);
      expect(find.text('Nama Bank · 001234567890'), findsOneWidget);
      expect(find.text('Nama Pemilik'), findsOneWidget);
      await tester.ensureVisible(find.text('I250001'));
      await tester.pumpAndSettle();
      expect(find.text('I250001'), findsOneWidget);
      expect(find.textContaining('KYC'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
