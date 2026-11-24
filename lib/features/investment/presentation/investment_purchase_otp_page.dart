import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../../core/widgets/visible_page_state.dart';
import '../../auth/domain/auth_session.dart';
import '../../forms/domain/form_preview.dart';
import '../data/investment_purchase_api.dart';

class InvestmentPurchaseOtpPage extends StatefulWidget {
  const InvestmentPurchaseOtpPage({
    super.key,
    required this.session,
    required this.item,
    this.api,
    this.refreshOnOpen = false,
  });
  final AuthSession session;
  final Map<String, dynamic> item;
  final InvestmentPurchaseApi? api;
  final bool refreshOnOpen;
  @override
  State<InvestmentPurchaseOtpPage> createState() =>
      _InvestmentPurchaseOtpPageState();
}

class _InvestmentPurchaseOtpPageState extends State<InvestmentPurchaseOtpPage>
    with VisiblePageState<InvestmentPurchaseOtpPage> {
  late final _api = widget.api ?? InvestmentPurchaseApi();
  late Map<String, dynamic> _item = Map.of(widget.item);
  late Map<String, dynamic> _otp = purchaseMap(_item['otp']);
  final _code = TextEditingController();
  DateTime _received = DateTime.now();
  Timer? _timer;
  DateTime? _lastRefresh;
  bool _busy = false, _terminal = false;
  late bool _syncFailed = widget.refreshOnOpen;
  String? _error;
  bool get _verified =>
      purchaseMap(_item['status'])['code'] == 'menunggu_approval';
  int get _elapsed =>
      DateTime.now().difference(_received).inSeconds.clamp(0, 1000000);
  int get _remaining =>
      (purchaseInt(_otp['remaining_seconds'] ?? _otp['expires_in']) - _elapsed)
          .clamp(0, 1000000);
  int get _cooldown =>
      (purchaseInt(_otp['resend_in_seconds']) - _elapsed).clamp(0, 1000000);
  bool get _resend =>
      !_verified &&
      !_terminal &&
      !_syncFailed &&
      _cooldown == 0 &&
      purchaseInt(_otp['resend_count']) < purchaseInt(_otp['resend_limit']) &&
      (_otp['can_resend'] == true ||
          purchaseInt(_otp['resend_in_seconds']) > 0);
  @override
  void onPageVisibilityChanged(bool visible) {
    _timer?.cancel();
    if (!visible || _verified || _terminal) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          pageVisible &&
          ((widget.refreshOnOpen && _lastRefresh == null) ||
              DateTime.now().difference(_received) >=
                  const Duration(seconds: 30))) {
        _refresh(force: false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool force = true}) async {
    if (_busy || !pageVisible || _verified || _terminal) return;
    if (!force &&
        _lastRefresh != null &&
        DateTime.now().difference(_lastRefresh!) <
            const Duration(seconds: 30)) {
      return;
    }
    _lastRefresh = DateTime.now();
    setState(() => _busy = true);
    try {
      await _sync();
    } catch (_) {
      if (mounted) {
        setState(() {
          _syncFailed = true;
          _error = 'Status belum dapat diperbarui. Coba periksa kembali.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sync() async {
    final items = await _api.pending(widget.session);
    if (!mounted) return;
    final matches = items.where((e) => e['id'] == _item['id']);
    setState(() {
      _syncFailed = false;
      if (matches.isEmpty) {
        _terminal = true;
        _timer?.cancel();
        _error =
            'Pengajuan tidak lagi aktif. Kembali ke Investasi untuk melihat status terbaru.';
      } else {
        _item = matches.first;
        _otp = purchaseMap(_item['otp']);
        _received = DateTime.now();
        if (_verified) _timer?.cancel();
      }
    });
  }

  Future<void> _act(bool resend) async {
    if (_busy || _verified || _terminal || _syncFailed) return;
    if (resend && !_resend) return;
    if (!resend &&
        (_remaining == 0 ||
            _otp['expired'] == true ||
            purchaseInt(_otp['remaining_attempts']) <= 0)) {
      return;
    }
    if (!resend && !RegExp(r'^\d{6}$').hasMatch(_code.text)) {
      setState(() => _error = 'Masukkan 6 digit kode OTP.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = resend
          ? await _api.resend(widget.session, purchaseInt(_item['id']))
          : await _api.verify(
              widget.session,
              purchaseInt(_item['id']),
              _code.text,
            );
      if (!mounted) return;
      if (resend) {
        _code.clear();
        await _sync();
      } else {
        final purchase = purchaseMap(result['purchase']);
        if (purchaseInt(purchase['id']) != purchaseInt(_item['id']) ||
            purchaseMap(purchase['status'])['code'] != 'menunggu_approval' ||
            result['next_action'] != 'admin_approval') {
          throw StateError('Approval status not confirmed');
        }
        setState(() {
          _item = {..._item, ...purchase};
          _otp = purchaseMap(result['otp']);
          _timer?.cancel();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is InvestmentPurchaseFailure
            ? e.message
            : 'Respons belum diterima. Memeriksa status pengajuan…',
      );
      // Reconcile with the read endpoint; never repeat an uncertain mutation.
      try {
        await _sync();
      } catch (_) {
        if (mounted) setState(() => _syncFailed = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Verifikasi pembelian')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              _verified
                  ? Icons.check_circle_outline
                  : Icons.verified_user_outlined,
              size: 48,
              color: AppTheme.teal,
            ),
            const SizedBox(height: 20),
            Text(
              _verified ? 'OTP berhasil diverifikasi' : 'Masukkan kode OTP',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              _verified
                  ? 'Pembelian menunggu approval admin. Buy Power belum dipotong.'
                  : 'Kode dikirim melalui WhatsApp ke ${_otp['destination'] ?? 'nomor terdaftar'}. Jangan bagikan kode kepada siapa pun.',
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_item['stock_name'] ?? _item['nama'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('${_item['total_lot'] ?? _item['jumlah_lot']} lot'),
                Text(
                  rupiah(purchaseInt(_item['total_nilai'] ?? _item['nilai'])),
                ),
                const SizedBox(height: 20),
              ],
            ),
            if (!_verified && !_terminal) ...[
              if (_otp['sent'] == false)
                const Text(
                  'Pengiriman WhatsApp belum berhasil. Anda dapat mengirim ulang saat tersedia.',
                ),
              TextField(
                controller: _code,
                enabled:
                    !_busy &&
                    !_syncFailed &&
                    _remaining > 0 &&
                    purchaseInt(_otp['remaining_attempts']) > 0,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30, letterSpacing: 12),
                decoration: const InputDecoration(
                  labelText: 'Kode OTP',
                  hintText: '••••••',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _remaining > 0
                    ? 'Berlaku ${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')} · Sisa ${purchaseInt(_otp['remaining_attempts'])} percobaan'
                    : 'Kode sudah kedaluwarsa. Kirim ulang untuk melanjutkan.',
              ),
              const SizedBox(height: 20),
              BasyaActionButton(
                label: 'Verifikasi pembelian',
                style: BasyaActionStyle.emphasis,
                expand: true,
                loading: _busy,
                onPressed:
                    !_syncFailed &&
                        _remaining > 0 &&
                        purchaseInt(_otp['remaining_attempts']) > 0
                    ? () => _act(false)
                    : null,
              ),
              TextButton(
                onPressed: !_busy && _resend ? () => _act(true) : null,
                child: Text(
                  _cooldown > 0
                      ? 'Kirim ulang dalam $_cooldown detik'
                      : 'Kirim ulang kode',
                ),
              ),
              if (purchaseInt(_otp['resend_count']) >=
                  purchaseInt(_otp['resend_limit']))
                const Text('Batas kirim ulang kode telah tercapai.'),
            ],
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppTheme.negative)),
            if (_syncFailed)
              TextButton(
                onPressed: _busy ? null : _refresh,
                child: const Text('Periksa status kembali'),
              ),
            if (_verified || _terminal)
              BasyaActionButton(
                label: 'Kembali ke Investasi',
                style: BasyaActionStyle.emphasis,
                expand: true,
                onPressed: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
    ),
  );
}
