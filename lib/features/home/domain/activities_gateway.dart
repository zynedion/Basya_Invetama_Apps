import '../../auth/domain/auth_session.dart';
import 'investor_home_data.dart';

abstract interface class ActivitiesGateway {
  Future<List<InvestorHomeActivity>> getActivities(
    AuthSession session, {
    int? limit,
    int? page,
    int? perPage,
  });
}

class ActivitiesPageData {
  const ActivitiesPageData({
    required this.items,
    required this.page,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
  });
  final List<InvestorHomeActivity> items;
  final int page;
  final int perPage;
  final int totalItems;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
}

abstract interface class PaginatedActivitiesGateway
    implements ActivitiesGateway {
  Future<ActivitiesPageData> getActivitiesPage(
    AuthSession session, {
    required int page,
    required int perPage,
  });
}
