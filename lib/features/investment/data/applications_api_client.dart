import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/authorized_request.dart';
import '../../auth/data/auth_exception.dart';
import '../../auth/domain/auth_session.dart';

class InvestmentApplication {
  InvestmentApplication(this.data);
  final Map<String, dynamic> data;
  String text(String key) => data[key] as String? ?? '';
  int number(String key) => (data[key] as num).toInt();
  Map get status => data['status'] as Map;
  Map get otp => data['otp'] as Map;
  String get owner =>
      data['owner'] is Map ? (data['owner']['name'] as String? ?? '') : '';
}

class ApplicationsData {
  const ApplicationsData(this.global, this.total, this.items);
  final bool global;
  final int total;
  final List<InvestmentApplication> items;
}

abstract interface class ApplicationsGateway {
  Future<ApplicationsData> getApplications(
    AuthSession session, {
    String? type,
    int? limit,
  });
}

class ApplicationsApiClient implements ApplicationsGateway {
  ApplicationsApiClient({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  void close() => _client.close();
  @override
  Future<ApplicationsData> getApplications(
    AuthSession session, {
    String? type,
    int? limit,
  }) async {
    try {
      final uri = Uri.https(
        'api.basyainvestama.id',
        '/app/investasi/pengajuan',
        {'type': ?type, if (limit != null) 'limit': '$limit'},
      );
      final response = await authorizedGet(_client, uri, session);
      if (response.statusCode == 401) {
        throw const AuthException(
          AuthFailureType.invalidCredentials,
          'Sesi Anda sudah tidak berlaku. Silakan masuk kembali.',
        );
      }
      if (response.statusCode != 200) {
        throw const AuthException(
          AuthFailureType.server,
          'Pengajuan belum dapat dimuat. Silakan coba lagi.',
        );
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map || body['status'] != true || body['data'] is! Map) {
        throw const FormatException();
      }
      final d = body['data'] as Map;
      if (d['currency'] != 'IDR' ||
          !['global', 'personal'].contains(d['scope']) ||
          d['jumlah_pengajuan'] is! num ||
          d['pengajuan'] is! List) {
        throw const FormatException();
      }
      final items = <InvestmentApplication>[];
      for (final v in d['pengajuan'] as List) {
        if (v is! Map<String, dynamic>) {
          throw const FormatException();
        }
        for (final k in [
          'id',
          'stock_id',
          'jumlah_lot',
          'harga_per_lot',
          'harga_per_lembar',
          'nilai',
        ]) {
          if (v[k] is! num || !(v[k] as num).isFinite) {
            throw const FormatException();
          }
        }
        for (final k in [
          'nama',
          'order_id',
          'kode_stock',
          'jenis',
          'diajukan_pada',
        ]) {
          if (v[k] is! String) {
            throw const FormatException();
          }
        }
        if (v['status'] is! Map ||
            v['status']['code'] is! String ||
            v['status']['label'] is! String ||
            v['otp'] is! Map) {
          throw const FormatException();
        }
        items.add(InvestmentApplication(Map.unmodifiable(v)));
      }
      return ApplicationsData(
        d['scope'] == 'global',
        (d['jumlah_pengajuan'] as num).toInt(),
        List.unmodifiable(items),
      );
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu memuat pengajuan habis. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Periksa koneksi internet Anda lalu coba lagi.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Respons pengajuan tidak dapat dibaca.',
      );
    }
  }
}
