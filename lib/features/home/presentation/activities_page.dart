import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/activities_gateway.dart';
import '../domain/investor_home_data.dart';
import 'activities_feed.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({
    super.key,
    required this.session,
    required this.gateway,
    required this.money,
    this.preview = const [],
  });
  final AuthSession? session;
  final ActivitiesGateway gateway;
  final String Function(int) money;
  final List<InvestorHomeActivity> preview;

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.loginCanvas,
    appBar: AppBar(
      title: const Text('Riwayat aktivitas'),
      backgroundColor: AppTheme.loginCanvas,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ActivitiesFeed(
            session: widget.session,
            gateway: widget.gateway,
            money: widget.money,
            preview: widget.preview,
            scrollable: true,
            header: const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivitas Anda',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Catatan transaksi dan pergerakan dana.',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
