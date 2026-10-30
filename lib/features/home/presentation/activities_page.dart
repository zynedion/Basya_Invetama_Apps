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
  final _feedKey = GlobalKey<ActivitiesFeedState>();
  Future<void> _refresh() async => _feedKey.currentState?.refresh();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.loginCanvas,
    appBar: AppBar(
      title: const Text('Riwayat aktivitas'),
      backgroundColor: AppTheme.loginCanvas,
    ),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Aktivitas Anda',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Catatan transaksi dan pergerakan dana.',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: ActivitiesFeed(
                        key: _feedKey,
                        session: widget.session,
                        gateway: widget.gateway,
                        money: widget.money,
                        preview: widget.preview,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
