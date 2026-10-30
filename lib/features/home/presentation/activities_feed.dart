import 'package:flutter/material.dart';
import '../../auth/data/auth_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/activities_gateway.dart';
import '../domain/investor_home_data.dart';
import 'activity_list.dart';

class ActivitiesFeed extends StatefulWidget {
  const ActivitiesFeed({
    super.key,
    required this.session,
    required this.gateway,
    required this.money,
    this.preview = const [],
    this.maxRows,
  });
  final AuthSession? session;
  final ActivitiesGateway gateway;
  final String Function(int) money;
  final List<InvestorHomeActivity> preview;
  final int? maxRows;

  @override
  State<ActivitiesFeed> createState() => ActivitiesFeedState();
}

class ActivitiesFeedState extends State<ActivitiesFeed> {
  List<InvestorHomeActivity>? _items;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ActivitiesFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.gateway != widget.gateway ||
        oldWidget.maxRows != widget.maxRows) {
      _load();
    }
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final request = ++_request;
    final session = widget.session;
    setState(() {
      _items = null;
      _error = null;
    });
    if (session == null) return;
    try {
      final items = await widget.gateway.getActivities(
        session,
        limit: widget.maxRows,
      );
      if (mounted && request == _request) setState(() => _items = items);
    } catch (error) {
      if (mounted && request == _request) {
        setState(
          () => _error = error is AuthException
              ? error.message
              : 'Aktivitas belum dapat dimuat.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.session == null ? widget.preview : _items;
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (items == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Belum ada aktivitas.', textAlign: TextAlign.center),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityList(
          activities: widget.maxRows == null
              ? items
              : items.take(widget.maxRows!).toList(),
          money: widget.money,
        ),
      ],
    );
  }
}
