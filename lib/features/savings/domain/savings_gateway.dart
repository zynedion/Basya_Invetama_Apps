import '../../auth/domain/auth_session.dart';
import 'savings_overview_data.dart';

enum SavingsType { pokok, wajib, sukarela }

abstract interface class SavingsGateway {
  Future<SavingsOverviewData> getSavings(
    AuthSession session, {
    SavingsType? type,
    int? limit,
  });
}
