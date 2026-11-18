import '../../../core/widgets/visible_page_state.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/domain/auth_session.dart';
import '../data/savings_withdraw_api.dart';
import 'savings_withdraw_page.dart';

class SavingsWithdrawPending extends StatefulWidget {
  const SavingsWithdrawPending({
    super.key,
    required this.session,
    required this.onChanged,
    this.visible = true,
  });
  final AuthSession session;
  final VoidCallback onChanged;
  final bool visible;
  @override
  State<SavingsWithdrawPending> createState() => _SavingsWithdrawPendingState();
}

class _SavingsWithdrawPendingState extends State<SavingsWithdrawPending>
    with VisiblePageState<SavingsWithdrawPending> {
  final _api = SavingsWithdrawApi();
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
        DateTime.now().difference(_lastAttempt!) < const Duration(seconds: 30)) {
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
          _error = 'Pengajuan penarikan belum dapat dimuat.';
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
    // Carry elapsed server durations into the OTP screen; do not restart its timer.
    final current = {
      ...item,
      'otp': {
        ...withdrawMap(item['otp']),
        'remaining_seconds': remaining,
        'resend_in_seconds': cooldown,
        'can_resend':
            cooldown == 0 &&
            (withdrawMap(item['otp'])['can_resend'] == true ||
                withdrawInt(withdrawMap(item['otp'])['resend_in_seconds']) >
                    0) &&
            withdrawInt(withdrawMap(item['otp'])['resend_count']) <
                withdrawInt(withdrawMap(item['otp'])['resend_limit']),
      },
    };
    _opening = true;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SavingsWithdrawOtpPage(session: widget.session, item: current),
      ),
    );
    if (mounted) {
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
          'Penarikan aktif',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final item in _items)
          WithdrawalPendingCard(
            key: ValueKey(item['id']),
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

class WithdrawalPendingCard extends StatefulWidget {
  const WithdrawalPendingCard({
    super.key,
    required this.item,
    required this.receivedAt,
    required this.onOpen,
    this.visible = true,
    this.enabled = true,
  });
  final Map<String, dynamic> item;
  final DateTime receivedAt;
  final void Function(int remaining, int cooldown) onOpen;
  final bool visible, enabled;
  @override
  State<WithdrawalPendingCard> createState() => _WithdrawalPendingCardState();
}

class _WithdrawalPendingCardState extends State<WithdrawalPendingCard>
    with VisiblePageState<WithdrawalPendingCard> {
  Timer? _timer;
  Map<String, dynamic> get _otp => withdrawMap(widget.item['otp']);
  bool get _waiting =>
      withdrawMap(widget.item['status'])['code'] == 'waiting_otp';
  int _seconds(dynamic value) =>
      (withdrawInt(value) -
              DateTime.now()
                  .difference(widget.receivedAt)
                  .inSeconds
                  .clamp(0, 10000000))
          .clamp(0, 10000000);
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant WithdrawalPendingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimer();
  }

  @override
  void onPageVisibilityChanged(bool visible) => _startTimer();

  void _startTimer() {
    _timer?.cancel();
    if (_waiting && pageVisible) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
        if (_seconds(_otp['remaining_seconds']) == 0 &&
            _seconds(_otp['resend_in_seconds']) == 0) {
          _timer?.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _seconds(_otp['remaining_seconds']);
    final cooldown = _seconds(_otp['resend_in_seconds']);
    final usable =
        remaining > 0 &&
        _otp['expired'] != true &&
        withdrawInt(_otp['remaining_attempts']) > 0;
    final hasResend =
        withdrawInt(_otp['resend_count']) < withdrawInt(_otp['resend_limit']);
    final label = !_waiting
        ? 'Lihat detail'
        : usable
        ? 'Masukkan OTP'
        : hasResend
        ? 'Perbarui OTP'
        : 'Lihat detail';
    final caption = !_waiting
        ? 'OTP terverifikasi · Menunggu admin'
        : usable
        ? 'Kode berlaku ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}'
        : !hasResend
        ? 'Kode tidak dapat digunakan. Batas kirim ulang tercapai.'
        : remaining == 0 || _otp['expired'] == true
        ? 'Kode kedaluwarsa'
        : 'Minta kode baru untuk melanjutkan';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _waiting ? const Color(0xFFEDF8F5) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _waiting ? Icons.verified_user_outlined : Icons.schedule,
                color: AppTheme.teal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _waiting ? 'Verifikasi penarikan' : 'Penarikan diproses',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.visible
                          ? withdrawalMoney(widget.item['amount'])
                          : 'Rp ••••••',
                      style: const TextStyle(color: AppTheme.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            caption,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: BasyaActionButton(
              label: label,
              icon: Icons.arrow_forward_rounded,
              style: _waiting
                  ? BasyaActionStyle.emphasis
                  : BasyaActionStyle.secondary,
              compact: true,
              onPressed: widget.enabled
                  ? () => widget.onOpen(remaining, cooldown)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
