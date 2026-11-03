import '../../auth/data/authorized_request.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/activities_gateway.dart';
import '../domain/investor_home_data.dart';

class ActivitiesApiClient implements PaginatedActivitiesGateway {
  ActivitiesApiClient({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static final activitiesUri = Uri.parse(
    'https://api.basyainvestama.id/app/activities',
  );
  void close() => _client.close();

  @override
  Future<List<InvestorHomeActivity>> getActivities(
    AuthSession session, {
    int? limit,
    int? page,
    int? perPage,
  }) async =>
      (await _fetch(session, limit: limit, page: page, perPage: perPage)).items;

  @override
  Future<ActivitiesPageData> getActivitiesPage(
    AuthSession session, {
    required int page,
    required int perPage,
  }) => _fetch(session, page: page, perPage: perPage, requirePagination: true);

  Future<ActivitiesPageData> _fetch(
    AuthSession session, {
    int? limit,
    int? page,
    int? perPage,
    bool requirePagination = false,
  }) async {
    final query = {
      if (limit != null) 'limit': '$limit',
      if (page != null) 'page': '$page',
      if (perPage != null) 'per_page': '$perPage',
    };
    try {
      final response = await authorizedGet(
        _client,
        query.isEmpty
            ? activitiesUri
            : activitiesUri.replace(queryParameters: query),
        session,
        headers: {
          'Accept': 'application/json',
          'Authorization': session.authorizationHeader,
        },
      );
      if (response.statusCode == 401) {
        throw const AuthException(
          AuthFailureType.invalidCredentials,
          'Sesi Anda sudah tidak berlaku. Silakan masuk kembali.',
        );
      }
      if (response.statusCode != 200) {
        throw const AuthException(
          AuthFailureType.server,
          'Aktivitas belum dapat dimuat. Silakan coba lagi.',
        );
      }
      final body = jsonDecode(response.body);
      if (body is! Map || body['status'] != true || body['data'] is! Map) {
        throw const FormatException();
      }
      final data = body['data'] as Map;
      // The app currently formats amounts in rupiah only.
      if (data['currency'] != 'IDR' || data['activities'] is! List) {
        throw const FormatException();
      }
      final items = (data['activities'] as List).map((item) {
        if (item is! Map ||
            item['title'] is! String ||
            item['amount'] is! num ||
            item['occurred_at'] is! String ||
            item['status'] is! Map ||
            item['status']['label'] is! String ||
            item['status']['code'] is! String ||
            item['reference_id'] is! String) {
          throw const FormatException();
        }
        final amount = item['amount'] as num;
        if (!amount.isFinite ||
            amount < 0 ||
            amount != amount.roundToDouble()) {
          throw const FormatException();
        }
        final date = DateTime.tryParse(item['occurred_at'] as String);
        if (date == null) throw const FormatException();
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ];
        final details = item['details'] is Map
            ? item['details'] as Map
            : const {};
        int? optionalNumber(dynamic value) {
          if (value is! num ||
              !value.isFinite ||
              value < 0 ||
              value != value.roundToDouble()) {
            return null;
          }
          return value.toInt();
        }

        return InvestorHomeActivity(
          id: item['id'] is String ? item['id'] as String : null,
          type: item['type'] is String ? item['type'] as String : null,
          occurredAt: item['occurred_at'] as String,
          stockId: optionalNumber(details['stock_id']),
          stockName: details['stock_name'] is String
              ? details['stock_name'] as String
              : null,
          lots: optionalNumber(details['lots']),
          price: optionalNumber(details['price']),
          grossAmount: optionalNumber(item['gross_amount']),
          taxAmount: optionalNumber(item['tax_amount']),
          title: item['title'] as String,
          date:
              '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
          amount: amount.toInt(),
          direction: switch (item['direction']) {
            'incoming' => HomeActivityDirection.incoming,
            'outgoing' => HomeActivityDirection.outgoing,
            'transfer' => HomeActivityDirection.transfer,
            _ => throw const FormatException(),
          },
          referenceId: item['reference_id'] as String,
          statusCode: item['status']['code'] as String,
          statusLabel: item['status']['label'] as String,
        );
      }).toList();
      final pagination = data['pagination'];
      if (pagination == null && !requirePagination) {
        return ActivitiesPageData(
          items: items,
          page: page ?? 1,
          perPage: perPage ?? items.length,
          totalItems: items.length,
          totalPages: 1,
          hasPrevious: false,
          hasNext: false,
        );
      }
      if (pagination is! Map) throw const FormatException();
      int integer(String key, int minimum) {
        final value = pagination[key];
        if (value is! int || value < minimum) throw const FormatException();
        return value;
      }

      final currentPage = integer('page', 1);
      final size = integer('per_page', 1);
      final total = integer('total_items', 0);
      final pages = integer('total_pages', 0);
      if (pagination['has_next'] is! bool ||
          pagination['has_previous'] is! bool ||
          (page != null && currentPage != page) ||
          (pagination['has_next'] == true && currentPage >= pages)) {
        throw const FormatException();
      }
      return ActivitiesPageData(
        items: List.unmodifiable(items),
        page: currentPage,
        perPage: size,
        totalItems: total,
        totalPages: pages,
        hasPrevious: pagination['has_previous'] as bool,
        hasNext: pagination['has_next'] as bool,
      );
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu memuat aktivitas habis. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Periksa koneksi internet Anda lalu coba lagi.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Respons aktivitas server tidak dapat dibaca.',
      );
    }
  }
}
