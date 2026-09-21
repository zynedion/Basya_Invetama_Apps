import '../../auth/domain/auth_session.dart';
import 'multiguna_overview_data.dart';

abstract interface class MultigunaGateway {
  Future<MultigunaOverviewData> getOverview(AuthSession session);
}
