import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/savings_gateway.dart';
import '../domain/savings_overview_data.dart';
import 'savings_transaction_row.dart';

class SavingsHistoryPage extends StatefulWidget {
  const SavingsHistoryPage({
    super.key,
    required this.session,
    required this.gateway,
    required this.money,
    this.preview = const [],
  });
  final AuthSession? session;
  final SavingsGateway gateway;
  final String Function(int) money;
  final List<SavingsTransaction> preview;
  @override
  State<SavingsHistoryPage> createState() => _SavingsHistoryPageState();
}

class _SavingsHistoryPageState extends State<SavingsHistoryPage> {
  SavingsType? _type;
  List<SavingsTransaction>? _items;
  String? _error;
  int _request = 0;
  bool _loading = false;
  String get _cacheKey => 'savings:${_type?.name ?? "all"}:all';
  void _clearCache() {
    if (!mounted) return;
    setState(() {
      _request++;
      _items = null;
      _loading = false;
      _error = 'Data sesi telah dibersihkan.';
    });
  }

  @override
  void dispose() {
    widget.session?.cache?.removeListener(_clearCache);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SavingsHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.gateway != widget.gateway) {
      oldWidget.session?.cache?.removeListener(_clearCache);
      widget.session?.cache?.addListener(_clearCache);
      _items = null;
      _load();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.session?.cache?.addListener(_clearCache);
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    final cache = widget.session?.cache;
    final key = _cacheKey;
    final ticket = cache?.begin(key);
    setState(() {
      _items = cache?.read<SavingsOverviewData>(key)?.transactions ?? _items;
      _loading = widget.session != null;
      _error = null;
    });
    final session = widget.session;
    if (session == null) {
      setState(
        () => _items = widget.preview
            .where((item) => _type == null || item.savingsType == _type!.name)
            .toList(),
      );
      return;
    }
    try {
      final data = await widget.gateway.getSavings(session, type: _type);
      if (mounted && request == _request) {
        if (cache != null && ticket != null) cache.write(key, data, ticket);
        setState(() {
          _items = data.transactions;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && request == _request) {
        if (error is AuthException &&
            error.type == AuthFailureType.invalidCredentials) {
          cache?.clear();
          _items = null;
        }
        setState(() {
          _loading = false;
          _error = error is AuthException
              ? error.message
              : 'Riwayat simpanan belum dapat dimuat.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.loginCanvas,
    appBar: AppBar(
      title: const Text('Riwayat simpanan'),
      backgroundColor: AppTheme.loginCanvas,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    for (final entry in <SavingsType?, String>{
                      null: 'Semua',
                      SavingsType.pokok: 'Pokok',
                      SavingsType.wajib: 'Wajib',
                      SavingsType.sukarela: 'Sukarela',
                    }.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _type == entry.key,
                          onSelected: (_) {
                            setState(() {
                              _type = entry.key;
                              _items = null;
                            });
                            _load();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (_items != null && _loading) const LinearProgressIndicator(),
              if (_items != null && _error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Menampilkan data terakhir; pembaruan gagal.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: _items == null || _items!.isEmpty
                        ? 1
                        : _items!.length,
                    itemBuilder: (context, index) {
                      if (_error != null && _items == null) {
                        return Column(
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        );
                      }
                      if (_items == null) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (_items!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Belum ada transaksi simpanan.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Column(
                        children: [
                          SavingsTransactionRow(
                            transaction: _items![index],
                            money: widget.money,
                          ),
                          if (index < _items!.length - 1)
                            const Divider(height: 1, indent: 52),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
