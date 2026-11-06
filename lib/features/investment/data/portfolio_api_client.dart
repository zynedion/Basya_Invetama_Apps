import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/authorized_request.dart';
import '../../auth/data/auth_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/portfolio_data.dart';

abstract interface class PortfolioGateway {
  Future<PortfolioData> getPortfolio(AuthSession session);
}

class PortfolioApiClient implements PortfolioGateway {
  PortfolioApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  void close() => _client.close();
  static final uri = Uri.parse(
    'https://api.basyainvestama.id/app/investasi/portofolio',
  );
  @override
  Future<PortfolioData> getPortfolio(AuthSession session) async {
    try {
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
          'Portofolio belum dapat dimuat. Silakan coba lagi.',
        );
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map || body['status'] != true || body['data'] is! Map) {
        throw const FormatException();
      }
      final data = body['data'] as Map;
      if (data['currency'] != 'IDR' ||
          data['portofolio'] is! List ||
          !['global', 'personal'].contains(data['scope'])) {
        throw const FormatException();
      }
      final items = <PortfolioItem>[];
      for (final raw in data['portofolio'] as List) {
        if (raw is! Map<String, dynamic>) throw const FormatException();
        for (final key in [
          'stock_id',
          'jumlah_lot',
          'lot_tersedia',
          'harga_per_lot',
          'modal',
          'profit',
          'pajak_profit',
          'profit_bersih',
          'nilai_saat_ini',
        ]) {
          if (raw[key] is! num || !(raw[key] as num).isFinite) {
            throw const FormatException();
          }
        }
        for (final key in [
          'nama',
          'kode',
          'lokasi',
          'sub_produk',
          'startup',
          'gambar',
          'logo',
          'status',
          'project_status',
          'aktivitas_terakhir_pada',
        ]) {
          if (raw[key] != null && raw[key] is! String) {
            throw const FormatException();
          }
        }
        items.add(PortfolioItem(raw));
      }
      return PortfolioData(
        isGlobal: data['scope'] == 'global',
        items: List.unmodifiable(items),
      );
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu memuat portofolio habis. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Periksa koneksi internet Anda lalu coba lagi.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Respons portofolio tidak dapat dibaca.',
      );
    }
  }
}
