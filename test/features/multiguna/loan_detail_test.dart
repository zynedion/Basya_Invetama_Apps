import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/multiguna/data/multiguna_api_client.dart';
import 'package:basya_investama/features/multiguna/domain/loan_detail.dart';
import 'package:basya_investama/features/multiguna/domain/installment_schedule.dart';
import 'package:basya_investama/features/multiguna/domain/multiguna_overview_data.dart';

void main() {
  final fixture = File(
    'test/fixtures/multiguna_detail.json',
  ).readAsStringSync();
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime(2099),
  );
  test(
    'numeric contract ID selects exact endpoint and parses schedule',
    () async {
      final client = MultigunaApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/app/multiguna/detail/292');
          expect(request.headers['Authorization'], 'Bearer test');
          return http.Response(fixture, 200);
        }),
      );
      final data = await client.getDetail(session, 292);
      expect(data.installments, hasLength(17));
      expect(data.installments.first.paid, isTrue);
      expect(data.installments[2].overdue, isTrue);
      expect(data.installments[3].label, 'Belum jatuh tempo');
      expect(data.installments.last.dueDate, DateTime(2027, 12, 20));
      expect(data.installments[2].amount, 0);
      expect(data.amount('installment'), 295294);
    },
  );
  test('rejects mismatched contract detail', () async {
    final client = MultigunaApiClient(
      client: MockClient((_) async => http.Response(fixture, 200)),
    );
    await expectLater(client.getDetail(session, 293), throwsException);
  });
  test(
    'calendar uses actual due dates and status, never generates extra dates',
    () {
      final detail = LoanDetail(jsonDecode(fixture)['data'] as Map);
      final loan = MultigunaLoan(
        id: 292,
        contractNumber: detail.reference,
        startDate: DateTime(2026, 8),
        endDate: DateTime(2028, 1, 20),
        installmentAmount: 295294,
        totalPayment: 590588,
        remainingBalance: 4429412,
        dueDay: 20,
        nextDueDate: DateTime(2026, 10, 20),
        paidInstallments: 2,
        totalInstallments: 17,
        nextInstallmentNumber: 3,
        collectibilityValue: -1,
        collectibilityLabel: 'COL -1',
        collectibilityCategory: 'warning',
        paymentStatusCode: 'overdue',
        paymentStatusLabel: 'Cicilan Belum Dibayar',
        arrearsMonths: 1,
        arrearsAmount: 295294,
      );
      final details = {292: detail};
      final paid = installmentsOn(
        [loan],
        DateTime(2026, 9, 20),
        details: details,
      ).single;
      expect(paid.paid, isTrue);
      expect(paid.overdue, isFalse);
      expect(paid.item!.paymentDate, DateTime(2026, 10, 12));
      expect(
        installmentsOn([loan], DateTime(2026, 10, 12), details: details),
        isEmpty,
      );
      expect(
        installmentsOn([loan], DateTime(2028, 1, 20), details: details),
        isEmpty,
      );
      expect(
        installmentsOn(
          [loan],
          DateTime(2026, 11, 20),
          details: details,
        ).single.amount,
        295294,
      );
    },
  );
}
