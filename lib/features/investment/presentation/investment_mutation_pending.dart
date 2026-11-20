import '../../../core/widgets/visible_page_state.dart';
import 'package:flutter/material.dart';
import '../../auth/domain/auth_session.dart';
import '../data/investment_mutation_api.dart';
import 'investment_mutation_page.dart';
import '../../savings/presentation/savings_withdraw_pending.dart'
    show WithdrawalPendingCard;

class InvestmentMutationPending extends StatefulWidget {
  const InvestmentMutationPending({
    super.key,
    required this.session,
    required this.onChanged,
    this.visible = true,
  });
  final AuthSession session;
  final VoidCallback onChanged;
  final bool visible;
  @override
  State<InvestmentMutationPending> createState() =>
      _InvestmentMutationPendingState();
}

class _InvestmentMutationPendingState extends State<InvestmentMutationPending>
    with VisiblePageState<InvestmentMutationPending> {
  final _api = InvestmentMutationApi();
  List<Map<String, dynamic>> _items = [];
  String? _error;
  bool _loading = false;
  bool _opening = false;
  DateTime _received = DateTime.now();
  DateTime? _lastAttempt;
  @override
  void onPageVisibilityChanged(bool visible) {
    if (!visible) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && pageVisible) _load(force: false);
    });
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = true}) async {
    if (_loading || _opening || !pageVisible) return;
    if (!force &&
        _lastAttempt != null &&
        DateTime.now().difference(_lastAttempt!) <
            const Duration(seconds: 30)) {
      return;
    }
    _lastAttempt = DateTime.now();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.pending(widget.session);
      if (mounted) {
        setState(() {
          _items = items;
          _received = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = [];
          _error = 'Pengajuan mutasi belum dapat dimuat.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(
    Map<String, dynamic> item,
    int remaining,
    int cooldown,
  ) async {
    if (_opening || _loading) return;
    // Carry elapsed server durations into the OTP screen; do not restart its timer.
    final current = {
      ...item,
      'otp': {
        ...mutationMap(item['otp']),
        'remaining_seconds': remaining,
        'resend_in_seconds': cooldown,
        'can_resend':
            cooldown == 0 &&
            (mutationMap(item['otp'])['can_resend'] == true ||
                mutationInt(mutationMap(item['otp'])['resend_in_seconds']) >
                    0) &&
            mutationInt(mutationMap(item['otp'])['resend_count']) <
                mutationInt(mutationMap(item['otp'])['resend_limit']),
      },
    };
    _opening = true;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            InvestmentMutationOtpPage(session: widget.session, item: current),
      ),
    );
    if (mounted) {
      _opening = false;
      _lastAttempt = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && pageVisible) _load(force: false);
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) ...[
        Text(_error!),
        TextButton(onPressed: _load, child: const Text('Coba lagi')),
      ],
      if (_items.isNotEmpty) ...[
        const Text(
          'Mutasi menunggu OTP',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final item in _items)
          WithdrawalPendingCard(
            key: ValueKey(item['id']),
            title: 'Verifikasi mutasi',
            item: item,
            receivedAt: _received,
            visible: widget.visible,
            enabled: !_loading,
            onOpen: (remaining, cooldown) => _open(item, remaining, cooldown),
          ),
        const SizedBox(height: 24),
      ],
    ],
  );
}
