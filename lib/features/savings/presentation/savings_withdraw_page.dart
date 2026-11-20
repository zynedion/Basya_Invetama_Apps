import '../../forms/domain/form_preview.dart'
    show RupiahInputFormatter, moneyValue;
import '../../../core/widgets/visible_page_state.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/domain/auth_session.dart';
import '../data/savings_withdraw_api.dart';

String withdrawalMoney(dynamic value) =>
    'Rp ${withdrawInt(value).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
List<Widget> withdrawalRecipient(Map<String, dynamic> recipient) {
  final bank = withdrawMap(recipient['bank_account']);
  final cash =
      bank['bank_name']?.toString().trim().toUpperCase() == 'CASH ON HAND';
  return cash
      ? [
          const Text('Tunai (Cash on Hand)'),
          Text('${recipient['name'] ?? 'Anggota'}'),
        ]
      : [
          Text(
            '${bank['bank_name'] ?? 'Rekening terdaftar'} · ${bank['account_no'] ?? '—'}',
          ),
          Text('${bank['account_name'] ?? recipient['name'] ?? '—'}'),
        ];
}

Widget withdrawalCard(List<Widget> children) => Container(
  padding: const EdgeInsets.all(20),
  margin: const EdgeInsets.only(bottom: 20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
    border: Border.all(color: AppTheme.cardBorder),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  ),
);
Widget withdrawalSummary(
  Map<String, dynamic> item,
  Map<String, dynamic> recipient,
) {
  return withdrawalCard([
    Text(
      withdrawalMoney(item['amount']),
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppTheme.teal,
      ),
    ),
    const SizedBox(height: 12),
    ...withdrawalRecipient(recipient),
    if (item['trx_id'] != null) ...[
      const SizedBox(height: 12),
      Text('${item['trx_id']}', style: const TextStyle(color: AppTheme.muted)),
    ],
  ]);
}

class SavingsWithdrawPage extends StatefulWidget {
  const SavingsWithdrawPage({super.key, required this.session, this.api});
  final AuthSession session;
  final SavingsWithdrawApi? api;
  @override
  State<SavingsWithdrawPage> createState() => _SavingsWithdrawPageState();
}

class _SavingsWithdrawPageState extends State<SavingsWithdrawPage> {
  late final _api = widget.api ?? SavingsWithdrawApi();
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  Map<String, dynamic>? _options;
  String? _error;
  bool _loading = true, _busy = false, _uncertain = false;
  bool _reviewing = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await _api.options(widget.session);
      if (mounted) setState(() => _options = value);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is SavingsWithdrawFailure
              ? e.message
              : 'Data penarikan belum dapat dimuat.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || _reviewing || _uncertain || !_form.currentState!.validate()) {
      return;
    }
    _reviewing = true;
    final amount = moneyValue(_amount.text);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi penarikan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            withdrawalSummary({
              'amount': amount,
            }, withdrawMap(_options!['recipient'])),
            const Text(
              'Verifikasi OTP melalui WhatsApp terlebih dahulu. Setelah itu, pengajuan diperiksa oleh admin sebelum dana dicairkan.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Periksa kembali'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    _reviewing = false;
    if (!mounted || confirmed != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _api.create(widget.session, amount, _note.text.trim());
      final item = withdrawMap(data['withdrawal']);
      if (withdrawInt(item['id']) <= 0) {
        throw StateError('Missing withdrawal ID');
      }
      item['otp'] = data['otp'];
      item['recipient'] = _options!['recipient'];
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              SavingsWithdrawOtpPage(session: widget.session, item: item),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uncertain =
            e is! SavingsWithdrawFailure || e.status >= 500 || e.status == 0;
        _error = _uncertain
            ? 'Status pengiriman belum dapat dipastikan. Kembali ke Simpanan dan periksa pengajuan aktif sebelum membuat penarikan lagi.'
            : (e as SavingsWithdrawFailure).message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options ?? {};
    final constraints = withdrawMap(options['constraints']);
    final eligibility = withdrawMap(options['eligibility']);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Withdraw Sukarela')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppTheme.negative)),
                const SizedBox(height: 12),
                if (_options == null)
                  TextButton(
                    onPressed: _loading ? null : _load,
                    child: const Text('Coba lagi'),
                  ),
              ],
              if (_options != null)
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      withdrawalCard([
                        const Text('Saldo tersedia'),
                        const SizedBox(height: 6),
                        Text(
                          withdrawalMoney(
                            withdrawMap(
                              options['balances'],
                            )['available_balance'],
                          ),
                          style: const TextStyle(
                            fontSize: 26,
                            color: AppTheme.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]),
                      const Text(
                        'Tujuan pencairan',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      withdrawalCard(
                        withdrawalRecipient(withdrawMap(options['recipient'])),
                      ),
                      if (eligibility['can_withdraw'] != true)
                        Text(
                          (eligibility['reasons'] as List? ??
                                  ['Penarikan belum tersedia untuk akun ini.'])
                              .join('\n'),
                        ),
                      TextFormField(
                        controller: _amount,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Nominal penarikan',
                          prefixText: 'Rp ',
                        ),
                        validator: (v) {
                          final amount = moneyValue(v ?? '');
                          if (amount <
                                  withdrawInt(constraints['minimum_amount']) ||
                              amount <= 0) {
                            return 'Masukkan nominal penarikan yang valid.';
                          }
                          if (amount >
                              withdrawInt(constraints['maximum_amount'])) {
                            return 'Nominal melebihi saldo tersedia.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _note,
                        enabled: !_busy,
                        maxLength:
                            withdrawInt(constraints['note_max_length']) > 0
                            ? withdrawInt(constraints['note_max_length'])
                            : 50,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Verifikasi OTP melalui WhatsApp, lalu pengajuan diperiksa oleh admin.',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 12),
                      BasyaActionButton(
                        label: 'Tinjau penarikan',
                        style: BasyaActionStyle.emphasis,
                        expand: true,
                        loading: _busy,
                        onPressed:
                            !_loading &&
                                !_uncertain &&
                                eligibility['can_withdraw'] == true
                            ? _submit
                            : null,
                      ),
                      if (_uncertain)
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kembali ke Simpanan'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavingsWithdrawOtpPage extends StatefulWidget {
  const SavingsWithdrawOtpPage({
    super.key,
    required this.session,
    required this.item,
    this.api,
  });
  final AuthSession session;
  final Map<String, dynamic> item;
  final SavingsWithdrawApi? api;
  @override
  State<SavingsWithdrawOtpPage> createState() => _SavingsWithdrawOtpPageState();
}

class _SavingsWithdrawOtpPageState extends State<SavingsWithdrawOtpPage>
    with VisiblePageState<SavingsWithdrawOtpPage> {
  late final _api = widget.api ?? SavingsWithdrawApi();
  late Map<String, dynamic> _item = Map.of(widget.item);
  late Map<String, dynamic> _otp = withdrawMap(_item['otp']);
  final _code = TextEditingController();
  DateTime _received = DateTime.now();
  Timer? _timer;
  DateTime? _lastRefresh;
  bool _busy = false, _terminal = false, _syncFailed = false;
  String? _error;
  bool get _verified =>
      withdrawMap(_item['status'])['code'] == 'waiting_admin' ||
      _otp['verified'] == true;
  int get _elapsed =>
      DateTime.now().difference(_received).inSeconds.clamp(0, 1000000);
  int get _remaining =>
      (withdrawInt(_otp['remaining_seconds'] ?? _otp['expires_in']) - _elapsed)
          .clamp(0, 1800);
  int get _cooldown =>
      (withdrawInt(_otp['resend_in_seconds']) - _elapsed).clamp(0, 1000000);
  bool get _resend =>
      !_verified &&
      !_terminal &&
      !_syncFailed &&
      _cooldown == 0 &&
      withdrawInt(_otp['resend_count']) < withdrawInt(_otp['resend_limit']) &&
      (_otp['can_resend'] == true ||
          withdrawInt(_otp['resend_in_seconds']) > 0);
  @override
  void onPageVisibilityChanged(bool visible) {
    _timer?.cancel();
    if (!visible) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          pageVisible &&
          DateTime.now().difference(_received) >= const Duration(seconds: 30)) {
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
    if (_busy || !pageVisible) return;
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
        _error =
            'Pengajuan tidak lagi aktif. Kembali ke Simpanan untuk melihat status terbaru.';
      } else {
        _item = matches.first;
        _otp = withdrawMap(_item['otp']);
        _received = DateTime.now();
      }
    });
  }

  Future<void> _act(bool resend) async {
    if (_busy) return;
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
          ? await _api.resend(widget.session, withdrawInt(_item['id']))
          : await _api.verify(
              widget.session,
              withdrawInt(_item['id']),
              _code.text,
            );
      if (!mounted) return;
      setState(() {
        _otp = withdrawMap(result['otp']);
        _received = DateTime.now();
        if (resend) {
          _code.clear();
          if (_otp['sent'] == false) {
            _error =
                'Kode belum berhasil dikirim melalui WhatsApp. Pengajuan Anda tetap tersimpan.';
          }
        } else {
          _item = {..._item, ...withdrawMap(result['withdrawal'])};
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is SavingsWithdrawFailure
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
      appBar: AppBar(title: const Text('Verifikasi penarikan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              _verified
                  ? Icons.hourglass_top_rounded
                  : Icons.verified_user_outlined,
              size: 48,
              color: AppTheme.teal,
            ),
            const SizedBox(height: 20),
            Text(
              _verified ? 'Menunggu verifikasi admin' : 'Masukkan kode OTP',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              _verified
                  ? 'OTP berhasil diverifikasi. Pengajuan menunggu persetujuan admin sebelum dana dicairkan.'
                  : 'Kode dikirim melalui WhatsApp ke ${_otp['destination'] ?? withdrawMap(_item['recipient'])['contact_masked'] ?? 'nomor terdaftar'}. Jangan bagikan kode kepada siapa pun.',
            ),
            const SizedBox(height: 20),
            withdrawalSummary(_item, withdrawMap(_item['recipient'])),
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
                    withdrawInt(_otp['remaining_attempts']) > 0,
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
                    ? 'Berlaku ${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')} · Sisa ${withdrawInt(_otp['remaining_attempts'])} percobaan'
                    : 'Kode sudah kedaluwarsa. Kirim ulang untuk melanjutkan.',
              ),
              const SizedBox(height: 20),
              BasyaActionButton(
                label: 'Verifikasi OTP',
                style: BasyaActionStyle.emphasis,
                expand: true,
                loading: _busy,
                onPressed:
                    !_syncFailed &&
                        _remaining > 0 &&
                        withdrawInt(_otp['remaining_attempts']) > 0
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
              if (withdrawInt(_otp['resend_count']) >=
                  withdrawInt(_otp['resend_limit']))
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
                label: 'Kembali ke Simpanan',
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
