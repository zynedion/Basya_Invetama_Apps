import 'dart:io';
import 'dart:ui' as ui;

import 'package:basya_investama/core/theme/app_theme.dart';
import 'package:basya_investama/core/widgets/basya_components.dart';
import 'package:basya_investama/features/forms/domain/form_preview.dart';
import 'package:basya_investama/features/forms/presentation/basya_form_page.dart';
import 'package:basya_investama/features/forms/presentation/form_routes.dart';
import 'package:basya_investama/features/forms/presentation/form_widgets.dart';
import 'package:basya_investama/features/navigation/presentation/main_container.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MemoryFile extends XFile {
  MemoryFile(this.fileName, this.data) : super('');
  final String fileName;
  final Uint8List data;
  @override
  String get name => fileName;
  @override
  Future<int> length() async => data.length;
  @override
  Future<Uint8List> readAsBytes() async => data;
}

Finder input(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> fill(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(input(label));
  await tester.enterText(input(label), value);
  await tester.pump();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: .35);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String label, String value) async {
  await tapVisible(tester, find.byKey(ValueKey(label)));
  await tapVisible(tester, find.widgetWithText(ListTile, value));
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  setUpAll(() async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'));
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> showForm(
    WidgetTester tester,
    BasyaFormKind kind, {
    double width = 390,
    double scale = 1,
    AttachmentPicker? picker,
    GlobalKey? boundary,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: BasyaFormPage(kind: kind, attachmentPicker: picker),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final kind in BasyaFormKind.values) {
    testWidgets(
      '${kind.name}: narrow layout and large text keep submit reachable',
      (tester) async {
        await showForm(tester, kind, width: 320, scale: 2);
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.byKey(const ValueKey('review-form')));
        expect(tester.takeException(), isNull);
        expect(
          find.byType(FormReviewSheet),
          kind == BasyaFormKind.editProfile ? findsOneWidget : findsNothing,
        );
      },
    );

    testWidgets('${kind.name}: default render', (tester) async {
      final boundary = GlobalKey();
      await showForm(tester, kind, boundary: boundary);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_FORM_PREVIEWS')) {
        Future<void> capture(String suffix) => tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('.dart_tool/form-previews')
            ..createSync(recursive: true);
          File(
            '${directory.path}/${kind.name}$suffix.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await capture('');
        await Scrollable.ensureVisible(
          tester.element(find.byKey(const ValueKey('review-form'))),
          alignment: .8,
        );
        await tester.pumpAndSettle();
        await capture('-bottom');
        if (kind == BasyaFormKind.financing) {
          await Scrollable.ensureVisible(
            tester.element(find.text('Simulasi dari Basya')),
            alignment: .1,
          );
          await tester.pumpAndSettle();
          await capture('-simulation');
        }
      }
    });
  }

  testWidgets(
    'mutation validates available balance, retains data after review, completes demo',
    (tester) async {
      await showForm(tester, BasyaFormKind.mutation);
      await fill(tester, 'Nominal mutasi', '6000000');
      await tapVisible(tester, find.byKey(const ValueKey('review-form')));
      expect(find.text('Nominal maksimal Rp 5.000.000.'), findsOneWidget);
      await fill(tester, 'Nominal mutasi', '1500000');
      await tapVisible(tester, find.byKey(const ValueKey('review-form')));
      expect(find.byType(FormReviewSheet), findsOneWidget);
      expect(
        tester
            .widget<FormReviewSheet>(find.byType(FormReviewSheet))
            .values['Nominal mutasi'],
        'Rp 1.500.000',
      );
      await tapVisible(tester, find.text('Kembali dan ubah'));
      expect(
        tester.widget<TextField>(input('Nominal mutasi')).controller!.text,
        '1.500.000',
      );
      await tapVisible(tester, find.byKey(const ValueKey('review-form')));
      await tapVisible(tester, find.text('Konfirmasi demo'));
      expect(find.text('Pratinjau selesai'), findsOneWidget);
      expect(
        find.textContaining('Tidak ada transaksi yang dikirim'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'password confirmation rejects mismatch and never exposes secrets in review',
    (tester) async {
      await showForm(tester, BasyaFormKind.password);
      await fill(tester, 'Kata sandi lama', 'old-secret');
      await fill(tester, 'Kata sandi baru', 'new-secret');
      await fill(tester, 'Konfirmasi kata sandi baru', 'wrong-secret');
      await tapVisible(tester, find.byKey(const ValueKey('review-form')));
      expect(
        find.text('Konfirmasi harus sama dengan kata sandi baru.'),
        findsOneWidget,
      );
      await fill(tester, 'Konfirmasi kata sandi baru', 'new-secret');
      await tapVisible(tester, find.byKey(const ValueKey('review-form')));
      final review = tester.widget<FormReviewSheet>(
        find.byType(FormReviewSheet),
      );
      expect(review.values.values.join(), isNot(contains('new-secret')));
      expect(review.values.values.join(), isNot(contains('old-secret')));
    },
  );

  testWidgets('payment date, destination and local proof lead to review', (
    tester,
  ) async {
    await showForm(
      tester,
      BasyaFormKind.topUpSavings,
      picker: (_) async => MemoryFile(
        'bukti.pdf',
        Uint8List.fromList('%PDF-1.4 test'.codeUnits),
      ),
    );
    await tapVisible(tester, find.byKey(const ValueKey('Tanggal transfer')));
    await tester.tap(find.text('Pilih').last);
    await tester.pumpAndSettle();
    await fill(tester, 'Nominal', '250000');
    await choose(
      tester,
      'Rekening tujuan',
      FormPreview.cooperativeAccounts.first,
    );
    await tapVisible(tester, find.text('Pilih berkas'));
    expect(find.text('bukti.pdf'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('review-form')));
    expect(find.byType(FormReviewSheet), findsOneWidget);
    expect(
      tester
          .widget<FormReviewSheet>(find.byType(FormReviewSheet))
          .values['Bukti pembayaran'],
      'bukti.pdf',
    );
  });

  testWidgets(
    'attachment can be replaced, cancelled and removed; oversize is rejected',
    (tester) async {
      var file = MemoryFile('large.pdf', Uint8List(6 * 1024 * 1024));
      var cancelled = false;
      LocalAttachment? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Form(
              child: BasyaAttachmentField(
                label: 'Bukti',
                onChanged: (value) => selected = value,
                picker: (_) async => cancelled ? null : file,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pilih berkas'));
      await tester.pumpAndSettle();
      expect(find.textContaining('maksimal 5 MB'), findsOneWidget);
      expect(selected, isNull);
      file = MemoryFile('bukti.pdf', Uint8List(32));
      await tester.tap(find.text('Pilih berkas'));
      await tester.pumpAndSettle();
      expect(selected?.name, 'bukti.pdf');
      cancelled = true;
      await tester.tap(find.text('Ganti berkas'));
      await tester.pumpAndSettle();
      expect(selected?.name, 'bukti.pdf');
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
    },
  );

  testWidgets(
    'financing updates preview calculation and rejects excess principal',
    (tester) async {
      await showForm(tester, BasyaFormKind.financing);
      await fill(tester, 'Harga penawaran', '10000000');
      await fill(tester, 'Uang muka', '3000000');
      await choose(tester, 'Jangka waktu', '12 bulan');
      expect(find.text('Rp 7.000.000'), findsOneWidget);
      expect(find.text('Rp 700.000'), findsOneWidget);
      expect(find.text('Rp 7.700.000'), findsOneWidget);
      await fill(tester, 'Uang muka', '1000000');
      await tapVisible(tester, find.byKey(const ValueKey('review-form')));
      expect(
        find.textContaining('plafon maksimal Rp 7.250.000'),
        findsOneWidget,
      );
    },
  );

  testWidgets('back preserves draft until explicitly discarded', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openBasyaForm(context, BasyaFormKind.mutation),
              child: const Text('Buka form'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka form'));
    await tester.pumpAndSettle();
    await fill(tester, 'Nominal mutasi', '100000');
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Tinggalkan form?'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan mengisi'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(input('Nominal mutasi')).controller!.text,
      '100.000',
    );
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Tinggalkan form'));
    await tester.pumpAndSettle();
    expect(find.text('Buka form'), findsOneWidget);
  });

  testWidgets('shared button works with keyboard activation', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BasyaActionButton(label: 'Kirim', onPressed: () => calls++),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('dashboard entry points open all nine form destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MainContainer()),
    );
    await tester.pumpAndSettle();
    Future<void> backFrom(BasyaFormKind kind) async {
      expect(
        tester.widget<BasyaFormPage>(find.byType(BasyaFormPage)).kind,
        kind,
      );
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.byType(BasyaFormPage), findsNothing);
    }

    await tapVisible(tester, find.text('Top Up'));
    await tester.tap(find.text('Buy Power').last);
    await tester.pumpAndSettle();
    await backFrom(BasyaFormKind.topUpBuyPower);
    await tapVisible(tester, find.text('Top Up'));
    await tester.tap(find.text('Simpanan Sukarela').last);
    await tester.pumpAndSettle();
    await backFrom(BasyaFormKind.topUpSavings);
    for (final entry in {
      'Withdraw': BasyaFormKind.withdraw,
      'Pinjam': BasyaFormKind.financing,
      'Mutasi': BasyaFormKind.mutation,
    }.entries) {
      await tapVisible(tester, find.text(entry.key));
      await backFrom(entry.value);
    }
    await tester.tap(find.byTooltip('Simpanan'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Bayar'));
    await backFrom(BasyaFormKind.mandatorySavings);
    await tester.tap(find.byTooltip('Multiguna'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Bayar cicilan'));
    await backFrom(BasyaFormKind.installment);
    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Edit profil'));
    await backFrom(BasyaFormKind.editProfile);
    await tapVisible(tester, find.text('Ganti password'));
    await backFrom(BasyaFormKind.password);
  });

  testWidgets(
    'keyboard inset leaves final password field and action scrollable',
    (tester) async {
      await showForm(tester, BasyaFormKind.password, width: 360);
      tester.view.viewInsets = const FakeViewPadding(bottom: 310);
      addTearDown(tester.view.resetViewInsets);
      await fill(tester, 'Konfirmasi kata sandi baru', 'new-secret');
      await tester.ensureVisible(find.byKey(const ValueKey('review-form')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final rect = tester.getRect(find.byKey(const ValueKey('review-form')));
      expect(rect.bottom, lessThanOrEqualTo(844 - 310));
    },
  );

  test('rupiah formatting handles pasted values, deletion and size limits', () {
    final formatter = RupiahInputFormatter();
    final formatted = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: 'Rp 1.250.000',
        selection: TextSelection.collapsed(offset: 12),
      ),
    );
    expect(formatted.text, '1.250.000');
    expect(moneyValue(formatted.text), 1250000);
    expect(
      formatter.formatEditUpdate(formatted, TextEditingValue.empty).text,
      '',
    );
    expect(
      formatter.formatEditUpdate(
        formatted,
        const TextEditingValue(text: '1234567890123'),
      ),
      formatted,
    );
  });
}
