import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/core/theme/app_theme.dart';
import 'package:basya_investama/features/auth/data/auth_exception.dart';
import 'package:basya_investama/features/auth/domain/auth_gateway.dart';
import 'package:basya_investama/features/auth/domain/auth_profile.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/auth/presentation/login_page.dart';
import 'package:basya_investama/features/auth/presentation/splash_page.dart';
import 'package:basya_investama/features/home/presentation/investor_home_page.dart';
import 'package:basya_investama/features/investment/presentation/investment_page.dart';
import 'package:basya_investama/features/multiguna/presentation/multiguna_page.dart';
import 'package:basya_investama/features/navigation/presentation/main_container.dart';
import 'package:basya_investama/features/profile/presentation/profile_page.dart';
import 'package:basya_investama/features/savings/presentation/savings_page.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'Back backgrounds the app and preserves selected tab; dialogs close first',
    (tester) async {
      var backgroundCalls = 0;
      const channel = MethodChannel('basya/app_lifecycle');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        expect(call.method, 'moveToBackground');
        backgroundCalls++;
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: MainContainer(auth: _FakeAuthGateway())),
      );
      await tester.tap(find.byTooltip('Simpanan'));
      await tester.pumpAndSettle();
      final pageState = tester.state(find.byType(MainContainer));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(backgroundCalls, 1);
      expect(tester.state(find.byType(MainContainer)), same(pageState));
      expect(find.byType(SavingsPage), findsOneWidget);
      showDialog<void>(
        context: tester.element(find.byType(SavingsPage)),
        builder: (_) => const AlertDialog(content: Text('Test dialog')),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Test dialog'), findsNothing);
      expect(backgroundCalls, 1);
    },
  );

  testWidgets(
    'Recreated main container restores the last tab for the account',
    (tester) async {
      Widget app() => MaterialApp(
        home: MainContainer(
          auth: _FakeAuthGateway(),
          profile: _FakeAuthGateway.profile,
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Simpanan'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(SavingsPage), findsOneWidget);
      expect(find.byType(InvestorHomePage), findsNothing);
    },
  );
  testWidgets('Login autofills username and leaves password empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          auth: _FakeAuthGateway(savedUsername: 'remembered-user'),
          animateBackground: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.first.controller!.text, 'remembered-user');
    expect(fields.last.controller!.text, isEmpty);
  });
  testWidgets(
    'Login validates fields and opens authenticated page on success',
    (tester) async {
      final auth = _FakeAuthGateway();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: LoginPage(auth: auth, animateBackground: false),
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
        home: LoginPage(auth: auth, animateBackground: false),
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
          child: const LoginPage(animateBackground: false),
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
      MaterialApp(
        home: SplashPage(
          auth: _FakeAuthGateway(),
          animateLoginBackground: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(LoginPage))).canPop(),
      isFalse,
    );
  });

  testWidgets('Active session skips splash and opens Home', (tester) async {
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(InvestorHomePage), findsOneWidget);
    expect(find.byType(SplashPage), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(InvestorHomePage))).canPop(),
      isFalse,
    );
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

  testWidgets('Investment hero metrics grow with larger text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.3),
          ),
          child: InvestmentPage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Modal aktif'), findsOneWidget);
    expect(find.text('Akumulasi profit'), findsOneWidget);
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

  testWidgets('Main navigation opens implemented tabs and profile page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainContainer(auth: _FakeAuthGateway()),
      ),
    );

    await tester.tap(find.byTooltip('Simpanan'));
    await tester.pumpAndSettle();
    expect(find.byType(SavingsPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('savings-voluntary-balance')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Investasi'));
    await tester.pumpAndSettle();
    expect(find.byType(InvestmentPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('investment-total-value')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('investment-page-scroll')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portofolio'));
    await tester.pumpAndSettle();
    expect(find.text('Green Valley Fund'), findsOneWidget);

    await tester.tap(find.byTooltip('Multiguna'));
    await tester.pumpAndSettle();
    expect(find.byType(MultigunaPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('multiguna-total-obligation')),
      findsOneWidget,
    );

    for (final label in ['Profil']) {
      await tester.tap(find.byTooltip(label));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(
        find.byKey(ValueKey('page-title-${label.toLowerCase()}')),
        findsOneWidget,
      );
      expect(find.text(label), findsNWidgets(2));
      expect(find.byKey(const ValueKey('profile-member-card')), findsOneWidget);
      expect(find.text('Informasi akun'), findsOneWidget);
      expect(find.text('Pengaturan akun'), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Beranda'));
    await tester.pumpAndSettle();
    expect(find.byType(InvestorHomePage), findsOneWidget);
  });

  testWidgets('Profile temporary logout clears session and opens login', (
    tester,
  ) async {
    final auth = _FakeAuthGateway();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainContainer(auth: auth),
      ),
    );

    await tester.tap(find.byTooltip('Profil'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.ensureVisible(
      find.byKey(const ValueKey('temporary-logout-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('temporary-logout-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(auth.logoutCalled, isTrue);
    expect(find.byType(LoginPage), findsOneWidget);
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
  _FakeAuthGateway({this.loginError, this.restoredSession, this.savedUsername});

  final String? savedUsername;

  final AuthException? loginError;
  final AuthSession? restoredSession;
  String? lastUsername;
  String? lastPassword;
  bool logoutCalled = false;

  @override
  Future<String?> readSavedUsername() async => savedUsername;

  @override
  Future<AuthSession?> readActiveSession() async => restoredSession;

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
  Future<void> logout() async => logoutCalled = true;

  @override
  Future<AuthSession?> restoreSession() async => restoredSession;
}
