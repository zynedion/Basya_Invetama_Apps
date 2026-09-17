import '../../auth/domain/auth_session.dart';
import 'home_summary.dart';

abstract interface class HomeSummaryGateway {
  Future<HomeSummary> getSummary(AuthSession session);
}
