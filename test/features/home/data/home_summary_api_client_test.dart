import 'dart:convert';

import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/home/data/home_summary_api_client.dart';
import 'package:basya_investama/features/home/domain/home_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('maps global summary and sends bearer authorization', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': true,
          'message': 'Summary berhasil diambil',
          'data': {
            'scope': 'global',
            'currency': 'IDR',
            'period': {'year': 2026, 'month': 9},
            'performa_investasi': {
              'periode_bulan': 6,
              'tipe': 'profit_bruto',
              'data': [
                {'year': 2026, 'month': 11, 'label': 'Nov', 'profit': 10815869},
              ],
            },
            'totals': {
              'total_nilai_investasi': 23276653802,
              'total_saldo': 655132334,
              'buy_power': 59484137,
              'simpanan_sukarela': 542148197,
              'simpanan_pokok': 21350000,
              'simpanan_wajib': 32150000,
              'dana_aktif_diinvestasikan': 20298000000,
              'profit_bulan_berjalan': 26133977,
              'akumulasi_total_profit': 2009462870,
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final gateway = HomeSummaryApiClient(client: client);
    final session = AuthSession(
      accessToken: 'test-token',
      tokenType: 'Bearer',
      expiresAt: DateTime.utc(2026, 9, 17, 12),
    );

    final result = await gateway.getSummary(session);

    expect(captured.method, 'GET');
    expect(captured.url, HomeSummaryApiClient.summaryUri);
    expect(captured.headers['Authorization'], 'Bearer test-token');
    expect(result.scope, HomeSummaryScope.global);
    expect(result.totalInvestmentValue, 23276653802);
    expect(result.performanceMonths, 6);
    expect(result.performanceType, 'profit_bruto');
    expect(result.performance.single.label, 'Nov');
    expect(result.performance.single.profit, 10815869);
    expect(result.totalBalance, 655132334);
    expect(result.totalSavings, 595648197);
    expect(result.profitPeriod, 'September 2026');
  });
}
