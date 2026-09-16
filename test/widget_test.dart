import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/core/theme/app_theme.dart';
import 'package:basya_investama/features/auth/data/auth_exception.dart';
import 'package:basya_investama/features/auth/domain/auth_gateway.dart';
import 'package:basya_investama/features/auth/domain/auth_profile.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/auth/presentation/login_page.dart';
import 'package:basya_investama/features/auth/presentation/splash_page.dart';
import 'package:basya_investama/features/home/presentation/investor_home_page.dart';
import 'package:basya_investama/features/navigation/presentation/main_container.dart';

void main() {
  testWidgets(
    'Login validates fields and opens authenticated page on success',
    (tester) async {
      final auth = _FakeAuthGateway();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: LoginPage(auth: auth),
        ),
      );
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan username atau email Anda.'), findsNothing);
      expect(find.text('Masukkan kata sandi Anda.'), findsNothing);
      await tester.enterText(find.byType(TextFormField).first, 'ANG-001');
      await tester.enterText(find.byType(TextFormField).last, 'password');
      await tester.tap(find.byTooltip('Tampilkan kata sandi'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse,
      );
      await tester.ensureVisible(find.text('Masuk'));
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestorHomePage), findsOneWidget);
      expect(find.text('Fakhri'), findsOneWidget);
      expect(find.text('Rp 17.500.000'), findsOneWidget);
      expect(auth.lastUsername, 'ANG-001');
      expect(auth.lastPassword, 'password');
    },
  );

  testWidgets('Login shows API error and keeps user on the form', (
    tester,
  ) async {
    final auth = _FakeAuthGateway(
      loginError: const AuthException(
        AuthFailureType.invalidCredentials,
        'Username atau password tidak valid',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginPage(auth: auth),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'wrong');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Username atau password tidak valid'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('Small screen with keyboard and large text can scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            viewInsets: EdgeInsets.only(bottom: 260),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const LoginPage(),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Splash opens login and cannot be returned to', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SplashPage(auth: _FakeAuthGateway())),
    );
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(LoginPage))).canPop(),
      isFalse,
    );
  });

  testWidgets('Splash restores a session that has not expired', (tester) async {
    final session = AuthSession(
      accessToken: 'restored-token',
      tokenType: 'Bearer',
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(auth: _FakeAuthGateway(restoredSession: session)),
      ),
    );
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.byType(InvestorHomePage), findsOneWidget);
  });

  testWidgets('Home hides every sensitive amount from the balance control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: InvestorHomePage(auth: _FakeAuthGateway()),
      ),
    );
    expect(find.text('Rp 17.500.000'), findsOneWidget);
    expect(find.text('Simpanan Sukarela'), findsOneWidget);
    expect(find.text('Total Simpanan'), findsNothing);
    expect(find.text('Rp 12.500.000'), findsOneWidget);
    expect(find.text('Rp 5.000.000'), findsOneWidget);
    expect(find.text('Rp 25.000.000'), findsOneWidget);

    await tester.tap(find.byTooltip('Sembunyikan saldo'));
    await tester.pump();

    expect(find.text('Rp 17.500.000'), findsNothing);
    expect(find.text('Rp 12.500.000'), findsNothing);
    expect(find.text('Rp 5.000.000'), findsNothing);
    expect(find.text('Rp 25.000.000'), findsNothing);
    expect(find.text('+Rp 500.000'), findsNothing);
  });

  testWidgets('Investor Home supports a narrow screen and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.5),
          ),
          child: InvestorHomePage(auth: _FakeAuthGateway()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Aksi cepat'), findsOneWidget);
    expect(find.text('Multiguna'), findsOneWidget);
    expect(find.text('Lihat jadwal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home uses iOS style bouncing scroll physics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: InvestorHomePage(auth: _FakeAuthGateway()),
      ),
    );

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollView.physics, isA<BouncingScrollPhysics>());
  });

  testWidgets('Home greeting follows the local time of day', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: InvestorHomePage(
          auth: _FakeAuthGateway(),
          now: () => DateTime(2026, 9, 15, 16),
        ),
      ),
    );

    expect(find.text('Selamat sore,'), findsOneWidget);
    expect(find.text('Selamat pagi,'), findsNothing);
  });

  testWidgets(
    'Non-investor Home hides investment surfaces and uses member nav',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MainContainer(
            auth: _FakeAuthGateway(),
            audience: HomeAudience.member,
          ),
        ),
      );

      expect(find.text('Raka Pratama'), findsOneWidget);
      expect(find.text('Simpanan Sukarela'), findsOneWidget);
      expect(find.text('Simpanan Wajib'), findsOneWidget);
      expect(find.text('Total Simpanan'), findsNothing);
      expect(find.text('Buy Power'), findsNothing);
      expect(find.text('Investasi Anda'), findsNothing);
      expect(find.byTooltip('Investasi'), findsNothing);
      expect(find.byTooltip('Simpanan'), findsOneWidget);
      expect(find.byTooltip('Multiguna'), findsOneWidget);
      expect(find.byTooltip('Profil'), findsOneWidget);
      expect(find.text('Multiguna'), findsOneWidget);
    },
  );

  testWidgets(
    'Home preview toggle switches between investor and member modes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: InvestorHomePage(auth: _FakeAuthGateway()),
        ),
      );

      expect(find.text('Nadia Putri'), findsOneWidget);
      expect(find.text('Investasi Anda'), findsOneWidget);

      await tester.tap(find.text('Non-investor'));
      await tester.pumpAndSettle();

      expect(find.text('Raka Pratama'), findsOneWidget);
      expect(find.text('Simpanan Sukarela'), findsOneWidget);
      expect(find.text('Simpanan Wajib'), findsOneWidget);
      expect(find.text('Investasi Anda'), findsNothing);

      await tester.tap(find.text('Investor'));
      await tester.pumpAndSettle();

      expect(find.text('Nadia Putri'), findsOneWidget);
      expect(find.text('Investasi Anda'), findsOneWidget);
    },
  );

  testWidgets('Non-investor Home uses a more compact bottom nav pill', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainContainer(auth: _FakeAuthGateway()),
      ),
    );
    final investorWidth = tester
        .getSize(find.byKey(const ValueKey('home-floating-nav-5')))
        .width;

    await tester.tap(find.text('Non-investor'));
    await tester.pumpAndSettle();

    final memberWidth = tester
        .getSize(find.byKey(const ValueKey('home-floating-nav-4')))
        .width;
    expect(memberWidth, lessThan(investorWidth));
    expect(memberWidth, 320);
  });

  testWidgets('Main navigation opens every investor placeholder tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainContainer(auth: _FakeAuthGateway()),
      ),
    );

    for (final label in ['Simpanan', 'Investasi', 'Multiguna', 'Profil']) {
      await tester.tap(find.byTooltip(label));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('page-title-${label.toLowerCase()}')),
        findsOneWidget,
      );
      expect(find.text(label), findsNWidgets(2));
    }

    await tester.tap(find.byTooltip('Beranda'));
    await tester.pumpAndSettle();
    expect(find.byType(InvestorHomePage), findsOneWidget);
  });

  testWidgets('Home keeps the hero fixed while its five activities scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: InvestorHomePage(auth: _FakeAuthGateway()),
      ),
    );
    final heroName = find.text('Nadia Putri');
    final initialHeroPosition = tester.getTopLeft(heroName);
    expect(find.text('Setoran sukarela'), findsOneWidget);
    expect(find.text('Pembelian investasi'), findsOneWidget);
    expect(find.text('Pembayaran cicilan'), findsOneWidget);
    expect(find.text('Top up Buy Power'), findsOneWidget);
    expect(find.text('Mutasi ke Sukarela'), findsOneWidget);

    await tester.ensureVisible(find.text('Mutasi ke Sukarela'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(heroName), initialHeroPosition);
  });

  testWidgets(
    'Home activity amounts use status color by transaction direction',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: InvestorHomePage(auth: _FakeAuthGateway()),
        ),
      );

      final incoming = tester.widget<Text>(find.text('+Rp 500.000'));
      expect(incoming.style?.color, AppTheme.positive);

      final outgoing = tester.widget<Text>(find.text('-Rp 1.500.000'));
      expect(outgoing.style?.color, AppTheme.negative);

      await tester.ensureVisible(find.text('Mutasi ke Sukarela'));
      await tester.pumpAndSettle();

      final transfer = tester.widget<Text>(find.text('Rp 750.000'));
      expect(transfer.style?.color, AppTheme.ink);
    },
  );
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({this.loginError, this.restoredSession});

  final AuthException? loginError;
  final AuthSession? restoredSession;
  String? lastUsername;
  String? lastPassword;

  static const profile = AuthProfile(
    id: '178',
    username: 'fakhri@mahirland.id',
    fullName: 'Fakhri',
    email: 'fakhri@mahirland.id',
    photo: 'default.png',
    groupLevel: 'root',
    active: true,
    hasNasabahProfile: false,
    hasInvestorProfile: false,
  );

  @override
  Future<AuthProfile> getProfile(AuthSession session) async => profile;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    lastUsername = username;
    lastPassword = password;
    if (loginError != null) throw loginError!;
    return AuthSession(
      accessToken: 'test-token',
      tokenType: 'Bearer',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restoreSession() async => restoredSession;
}
