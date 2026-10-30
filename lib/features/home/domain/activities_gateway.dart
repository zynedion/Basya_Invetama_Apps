import '../../auth/domain/auth_session.dart';
import 'investor_home_data.dart';

abstract interface class ActivitiesGateway {
  Future<List<InvestorHomeActivity>> getActivities(
    AuthSession session, {
    int? limit,
  });
}
