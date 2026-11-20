import '../../forms/domain/form_preview.dart'
    show RupiahInputFormatter, moneyValue;
import '../../../core/widgets/visible_page_state.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/domain/auth_session.dart';
import '../data/investment_mutation_api.dart';

import '../../savings/presentation/savings_withdraw_page.dart'
    show withdrawalCard, withdrawalMoney;

Widget mutationSummary(Map<String, dynamic> item) => withdrawalCard([
  const Text('Buy Power → Simpanan Sukarela'),
  const SizedBox(height: 12),
  Text(
    withdrawalMoney(item['amount']),
    style: const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: AppTheme.teal,
    ),
  ),
  const SizedBox(height: 8),
  Text('Biaya ${withdrawalMoney(item['fee'])}'),
  if (item['trx_id'] != null)
    Text('${item['trx_id']}', style: const TextStyle(color: AppTheme.muted)),
]);

class InvestmentMutationPage extends StatefulWidget {
  const InvestmentMutationPage({super.key, required this.session, this.api});
  final AuthSession session;
  final InvestmentMutationApi? api;
  @override
  State<InvestmentMutationPage> createState() => _InvestmentMutationPageState();
}

class _InvestmentMutationPageState extends State<InvestmentMutationPage> {
  late final _api = widget.api ?? InvestmentMutationApi();
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
          () => _error = e is InvestmentMutationFailure
              ? e.message
              : 'Data mutasi belum dapat dimuat.',
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
        title: const Text('Konfirmasi mutasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            mutationSummary({'amount': amount, 'fee': _options!['fee']}),
            const Text(
              'Setelah OTP diverifikasi, saldo langsung dipindahkan ke Simpanan Sukarela.',
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
      final item = mutationMap(data['mutation']);
      if (mutationInt(item['id']) <= 0 || data['otp'] is! Map) {
        throw StateError('Missing mutation ID');
      }
      item['otp'] = data['otp'];
      item['fee'] = _options!['fee'];
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InvestmentMutationOtpPage(
            session: widget.session,
            item: item,
            api: widget.api,
          ),
        ),
      );
      if (mounted) {
        setState(() => _busy = false);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uncertain =
            e is! InvestmentMutationFailure || e.status >= 500 || e.status == 0;
        _error = _uncertain
            ? 'Status pengiriman belum dapat dipastikan. Kembali ke Investasi dan periksa pengajuan aktif sebelum membuat mutasi lagi.'
            : (e as InvestmentMutationFailure).message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options ?? {};
    final source = mutationMap(options['source']);
    final eligibility = mutationMap(options['eligibility']);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Mutasi ke Sukarela')),
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
                        const Text('Buy Power tersedia'),
                        const SizedBox(height: 6),
                        Text(
                          withdrawalMoney(
                            mutationMap(options['source'])['available_balance'],
                          ),
                          style: const TextStyle(
                            fontSize: 26,
                            color: AppTheme.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]),
                      withdrawalCard([
                        const Text('Tujuan: Simpanan Sukarela'),
                        Text(
                          'Saldo ${withdrawalMoney(mutationMap(options['destination'])['balance'])}',
                        ),
                        Text('Biaya ${withdrawalMoney(options['fee'])}'),
                      ]),
                      if (eligibility['can_mutate'] != true)
                        Text(
                          (eligibility['reasons'] as List? ??
                                  ['Mutasi belum tersedia untuk akun ini.'])
                              .join('\n'),
                        ),
                      TextFormField(
                        controller: _amount,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Nominal mutasi',
                          prefixText: 'Rp ',
                        ),
                        validator: (v) {
                          final amount = moneyValue(v ?? '');
                          if (amount <= 0) {
                            return 'Masukkan nominal mutasi yang valid.';
                          }
                          if (amount >
                              mutationInt(source['available_balance'])) {
                            return 'Nominal melebihi saldo tersedia.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _note,
                        enabled: !_busy,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Verifikasi OTP melalui WhatsApp untuk memindahkan saldo.',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 12),
                      BasyaActionButton(
                        label: 'Tinjau mutasi',
                        style: BasyaActionStyle.emphasis,
                        expand: true,
                        loading: _busy,
                        onPressed:
                            !_loading &&
                                !_uncertain &&
                                eligibility['can_mutate'] == true
                            ? _submit
                            : null,
                      ),
                      if (_uncertain)
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kembali ke Investasi'),
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

class InvestmentMutationOtpPage extends StatefulWidget {
  const InvestmentMutationOtpPage({
    super.key,
    required this.session,
    required this.item,
    this.api,
  });
  final AuthSession session;
  final Map<String, dynamic> item;
  final InvestmentMutationApi? api;
  @override
  State<InvestmentMutationOtpPage> createState() =>
      _InvestmentMutationOtpPageState();
}

class _InvestmentMutationOtpPageState extends State<InvestmentMutationOtpPage>
    with VisiblePageState<InvestmentMutationOtpPage> {
  late final _api = widget.api ?? InvestmentMutationApi();
  late Map<String, dynamic> _item = Map.of(widget.item);
  late Map<String, dynamic> _otp = mutationMap(_item['otp']);
  final _code = TextEditingController();
  DateTime _received = DateTime.now();
  Timer? _timer;
  DateTime? _lastRefresh;
  bool _busy = false, _terminal = false, _syncFailed = false;
  String? _error;
  bool get _verified => mutationMap(_item['status'])['code'] == 'completed';
  int get _elapsed =>
      DateTime.now().difference(_received).inSeconds.clamp(0, 1000000);
  int get _remaining =>
      (mutationInt(_otp['remaining_seconds'] ?? _otp['expires_in']) - _elapsed)
          .clamp(0, 1000000);
  int get _cooldown =>
      (mutationInt(_otp['resend_in_seconds']) - _elapsed).clamp(0, 1000000);
  bool get _resend =>
      !_verified &&
      !_terminal &&
      !_syncFailed &&
      _cooldown == 0 &&
      mutationInt(_otp['resend_count']) < mutationInt(_otp['resend_limit']) &&
      (_otp['can_resend'] == true ||
          mutationInt(_otp['resend_in_seconds']) > 0);
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
        _otp = mutationMap(_item['otp']);
        _received = DateTime.now();
      }
    });
  }

  Future<void> _act(bool resend) async {
    if (_busy || _verified || _terminal || _syncFailed) return;
    if (resend && !_resend) return;
    if (!resend &&
        (_remaining == 0 ||
            _otp['expired'] == true ||
            mutationInt(_otp['remaining_attempts']) <= 0)) {
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
          ? await _api.resend(widget.session, mutationInt(_item['id']))
          : await _api.verify(
              widget.session,
              mutationInt(_item['id']),
              _code.text,
            );
      if (!mounted) return;
      if (resend) {
        if (mutationInt(result['mutation_id']) != mutationInt(_item['id']) ||
            result['otp'] is! Map) {
          throw StateError('Invalid resend response');
        }
      } else if (mutationMap(
            mutationMap(result['mutation'])['status'],
          )['code'] !=
          'completed') {
        throw StateError('Mutation completion not confirmed');
      }
      setState(() {
        _otp = mutationMap(result['otp']);
        _received = DateTime.now();
        if (resend) {
          _code.clear();
          if (_otp['sent'] == false) {
            _error =
                'Kode belum berhasil dikirim melalui WhatsApp. Pengajuan Anda tetap tersimpan.';
          }
        } else {
          _item = {..._item, ...mutationMap(result['mutation'])};
          _timer?.cancel();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is InvestmentMutationFailure
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
      appBar: AppBar(title: const Text('Verifikasi mutasi')),
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
              _verified ? 'Mutasi berhasil' : 'Masukkan kode OTP',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              _verified
                  ? 'Saldo berhasil dipindahkan dari Buy Power ke Simpanan Sukarela.'
                  : 'Kode dikirim melalui WhatsApp ke ${_otp['destination'] ?? 'nomor terdaftar'}. Jangan bagikan kode kepada siapa pun.',
            ),
            const SizedBox(height: 20),
            mutationSummary(_item),
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
                    mutationInt(_otp['remaining_attempts']) > 0,
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
                    ? 'Berlaku ${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')} · Sisa ${mutationInt(_otp['remaining_attempts'])} percobaan'
                    : 'Kode sudah kedaluwarsa. Kirim ulang untuk melanjutkan.',
              ),
              const SizedBox(height: 20),
              BasyaActionButton(
                label: 'Verifikasi & pindahkan saldo',
                style: BasyaActionStyle.emphasis,
                expand: true,
                loading: _busy,
                onPressed:
                    !_syncFailed &&
                        _remaining > 0 &&
                        mutationInt(_otp['remaining_attempts']) > 0
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
              if (mutationInt(_otp['resend_count']) >=
                  mutationInt(_otp['resend_limit']))
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
