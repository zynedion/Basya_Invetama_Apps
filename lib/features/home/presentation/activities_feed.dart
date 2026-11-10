import '../../../core/widgets/history_card_segment.dart';
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
    this.scrollable = false,
    this.header,
  });
  final AuthSession? session;
  final ActivitiesGateway gateway;
  final String Function(int) money;
  final List<InvestorHomeActivity> preview;
  final int? maxRows;
  final bool scrollable;
  final Widget? header;

  @override
  State<ActivitiesFeed> createState() => ActivitiesFeedState();
}

class ActivitiesFeedState extends State<ActivitiesFeed> {
  List<InvestorHomeActivity>? _items;
  String? _error;
  int _request = 0;
  static const _pageSize = 20;
  final _scrollController = ScrollController();
  bool get _paginated => widget.scrollable && widget.session != null;
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _loadingFirst = false;
  String? _moreError;

  Future<ActivitiesPageData> _fetchPage(int page) async {
    final gateway = widget.gateway;
    if (gateway is PaginatedActivitiesGateway) {
      return gateway.getActivitiesPage(
        widget.session!,
        page: page,
        perPage: _pageSize,
      );
    }
    // Compatibility for injected non-paginated preview/test gateways.
    final items = await gateway.getActivities(
      widget.session!,
      page: page,
      perPage: _pageSize,
    );
    return ActivitiesPageData(
      items: items,
      page: page,
      perPage: _pageSize,
      totalItems: items.length,
      totalPages: page,
      hasPrevious: page > 1,
      hasNext: items.length >= _pageSize,
    );
  }

  void _checkNextPage() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 300) {
      _loadMore();
    }
  }

  void _checkAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkNextPage();
    });
  }

  Future<void> _loadMore() async {
    if (!_paginated ||
        !_hasMore ||
        _loadingFirst ||
        _loadingMore ||
        _error != null ||
        _moreError != null) {
      return;
    }
    final request = _request;
    final nextPage = _page + 1;
    setState(() => _loadingMore = true);
    try {
      final result = await _fetchPage(nextPage);
      final more = result.items;
      if (!mounted || request != _request) return;
      final seen = (_items ?? [])
          .map((item) => item.id)
          .whereType<String>()
          .toSet();
      final additions = more
          .where((item) => item.id == null || seen.add(item.id!))
          .toList();
      setState(() {
        _items = List.unmodifiable([...?_items, ...additions]);
        _page = result.page;
        _hasMore = result.hasNext;
        _loadingMore = false;
      });
      _checkAfterLayout();
    } catch (error) {
      if (!mounted || request != _request) return;
      if (error is AuthException &&
          error.type == AuthFailureType.invalidCredentials) {
        widget.session?.cache?.clear();
        setState(() {
          _items = null;
          _hasMore = false;
          _error = error.message;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _loadingMore = false;
          _moreError = 'Aktivitas berikutnya belum dapat dimuat.';
        });
      }
    }
  }

  String get _cacheKey => _paginated
      ? 'activities:page1:20'
      : 'activities:${widget.maxRows ?? "all"}';
  bool _refreshing = false;

  void _cacheCleared() {
    if (!mounted) return;
    setState(() {
      _request++;
      _hasMore = false;
      _loadingMore = false;
      _loadingFirst = false;
      _moreError = null;
      _items = null;
      _refreshing = false;
      _error = 'Data sesi telah dibersihkan.';
    });
  }

  @override
  void dispose() {
    widget.session?.cache?.removeListener(_cacheCleared);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkNextPage);
    widget.session?.cache?.addListener(_cacheCleared);
    _load();
  }

  @override
  void didUpdateWidget(covariant ActivitiesFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.gateway != widget.gateway ||
        oldWidget.maxRows != widget.maxRows ||
        oldWidget.scrollable != widget.scrollable) {
      oldWidget.session?.cache?.removeListener(_cacheCleared);
      widget.session?.cache?.addListener(_cacheCleared);
      _items = null;
      _load();
    }
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final request = ++_request;
    final session = widget.session;
    final cache = session?.cache;
    final key = _cacheKey;
    final ticket = cache?.begin(key);
    setState(() {
      _items = cache?.read<List<InvestorHomeActivity>>(key) ?? _items;
      _error = null;
      _moreError = null;
      _loadingMore = false;
      _hasMore = false;
      _page = 1;
      _loadingFirst = session != null;
      _refreshing = session != null && _items != null;
    });
    if (session == null) return;
    try {
      final result = _paginated ? await _fetchPage(1) : null;
      final items =
          result?.items ??
          await widget.gateway.getActivities(session, limit: widget.maxRows);
      if (!mounted || request != _request) return;
      final snapshot = List<InvestorHomeActivity>.unmodifiable(items);
      if (cache != null && ticket != null) cache.write(key, snapshot, ticket);
      setState(() {
        _items = snapshot;
        _hasMore = result?.hasNext ?? false;
        _page = result?.page ?? 1;
        _loadingFirst = false;
        _refreshing = false;
      });
      _checkAfterLayout();
    } catch (error) {
      if (mounted && request == _request) {
        if (error is AuthException &&
            error.type == AuthFailureType.invalidCredentials) {
          cache?.clear();
        }
        setState(() {
          _refreshing = false;
          _loadingFirst = false;
          if (error is AuthException &&
              error.type == AuthFailureType.invalidCredentials) {
            _items = null;
          }
          _error = error is AuthException
              ? error.message
              : 'Aktivitas belum dapat dimuat.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.scrollable) return _buildContent(context);
    final items = widget.session == null ? widget.preview : _items;
    final hasItems = items != null && items.isNotEmpty;
    final count = hasItems ? items.length : 1;
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: count + 1 + ((_hasMore || _moreError != null) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget.header ?? const SizedBox.shrink(),
                if (_items != null) _cacheStatus(),
              ],
            );
          }
          if (index == count + 1) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: _moreError != null
                    ? Column(
                        children: [
                          Text(_moreError!, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: () {
                              setState(() => _moreError = null);
                              _loadMore();
                            },
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      )
                    : const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            );
          }
          final row = index - 1;
          return HistoryCardSegment(
            first: row == 0,
            last: row == count - 1,
            child: hasItems
                ? Column(
                    children: [
                      ActivityRow(activity: items[row], money: widget.money),
                      if (row < count - 1) const Divider(height: 1, indent: 52),
                    ],
                  )
                : _buildContent(context),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final items = widget.session == null ? widget.preview : _items;
    if (_error != null && items == null) {
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
      return Column(
        children: [
          if (!widget.scrollable) _cacheStatus(),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Belum ada aktivitas.', textAlign: TextAlign.center),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.scrollable) _cacheStatus(),
        ActivityList(
          activities: widget.maxRows == null
              ? items
              : items.take(widget.maxRows!).toList(),
          money: widget.money,
        ),
      ],
    );
  }

  Widget _cacheStatus() {
    if (_refreshing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (_error != null && _items != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            const Text(
              'Menampilkan data terakhir; pembaruan gagal.',
              textAlign: TextAlign.center,
            ),
            TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
