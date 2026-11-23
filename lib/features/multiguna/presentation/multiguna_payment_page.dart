import 'package:flutter/material.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/domain/auth_session.dart';
import '../../forms/domain/form_preview.dart';
import '../../forms/presentation/form_widgets.dart';
import '../data/multiguna_payment_api.dart';

int paymentNumber(dynamic v) => int.tryParse('$v') ?? 0;
String? validateInstallmentAmount(int amount, Map rule) {
  if (amount <= 0 || amount > paymentNumber(rule['maximum'])) {
    return 'Nominal harus lebih dari nol dan tidak melebihi sisa kewajiban.';
  }
  if (amount == paymentNumber(rule['settlement_amount'])) return null;
  final multiple = paymentNumber(rule['multiple_of']);
  if (amount < paymentNumber(rule['minimum']) ||
      multiple <= 0 ||
      amount % multiple != 0) {
    return 'Gunakan kelipatan ${rupiah(multiple)} atau pilih pelunasan.';
  }
  return null;
}

Widget paymentAllocation(Map payment) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    FormValue(
      'Total pembayaran',
      rupiah(paymentNumber(payment['amount'])),
      prominent: true,
    ),
    if (payment['outstanding_after'] != null)
      FormValue(
        'Sisa kewajiban setelah disetujui',
        rupiah(paymentNumber(payment['outstanding_after'])),
      ),
    for (final row in payment['allocations'] as List? ?? [])
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Cicilan ke-${row['installment_to']} · ${row['period']}'),
        subtitle: Text(
          'Pokok ${rupiah(paymentNumber(row['principal']))} · Margin ${rupiah(paymentNumber(row['margin']))}',
        ),
        trailing: Text(rupiah(paymentNumber(row['amount']))),
      ),
  ],
);
Future<void> showPendingPayment(
  BuildContext context,
  Map payment,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: .8,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Pembayaran menunggu verifikasi',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text('${payment['contract_trx_id']}'),
        Text('${payment['trx_id']}'),
        paymentAllocation(payment),
        if (payment['bank_account'] is Map)
          FormValue(
            'Rekening tujuan',
            '${payment['bank_account']['bank_name']} · ${payment['bank_account']['account_no']}',
          ),
        if (payment['note'] != null) FormValue('Catatan', '${payment['note']}'),
        const Text('Cicilan diperbarui setelah pembayaran disetujui admin.'),
      ],
    ),
  ),
);

class MultigunaPaymentPage extends StatefulWidget {
  const MultigunaPaymentPage({
    super.key,
    required this.session,
    required this.contractId,
    this.api,
  });
  final AuthSession session;
  final int contractId;
  final MultigunaPaymentApi? api;
  @override
  State<MultigunaPaymentPage> createState() => _MultigunaPaymentPageState();
}

class _MultigunaPaymentPageState extends State<MultigunaPaymentPage> {
  late final _api = widget.api ?? MultigunaPaymentApi();
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  Map<String, dynamic>? _options, _preview;
  String? _error;
  int? _account;
  DateTime? _date;
  LocalAttachment? _proof;
  bool _loading = true, _busy = false, _uncertain = false;
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
      final data = await _api.options(widget.session, widget.contractId);
      if (paymentNumber(data['contract']['id']) != widget.contractId) {
        throw StateError('Contract mismatch');
      }
      if (mounted) setState(() => _options = data);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is MultigunaPaymentFailure
              ? e.message
              : 'Pilihan pembayaran belum dapat dimuat.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review() async {
    if (_busy || _uncertain || !_form.currentState!.validate()) return;
    final amount = moneyValue(_amount.text);
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    bool submitting = false;
    try {
      final result = await _api.preview(
        widget.session,
        widget.contractId,
        amount,
      );
      if (!mounted) return;
      final payment = Map<String, dynamic>.from(result['payment'] as Map);
      if (paymentNumber(result['contract']['id']) != widget.contractId ||
          paymentNumber(payment['amount']) != amount ||
          payment['allocations'] is! List) {
        throw StateError('Invalid preview');
      }
      _preview = payment;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tinjau pembayaran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                paymentAllocation(payment),
                const Text(
                  'Pembayaran dialokasikan mulai dari cicilan paling lama dan menunggu verifikasi admin.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Kembali'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kirim pembayaran'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      submitting = true;
      final submitted = await _api.submit(
        widget.session,
        widget.contractId,
        amount: paymentNumber(_preview!['amount']),
        date: _date!,
        accountId: _account!,
        note: _note.text.trim(),
        proof: _proof!,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Pembayaran berhasil dikirim'),
            content: Text(
              'Menunggu verifikasi admin.\n\nNomor transaksi: ${submitted['trx_id']}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Selesai'),
              ),
            ],
          ),
        ),
      );
      if (mounted) {
        setState(() => _busy = false);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uncertain =
              submitting && (e is! MultigunaPaymentFailure || e.uncertain);
          _error = _uncertain
              ? 'Hasil pengiriman belum dapat dipastikan. Kembali dan periksa pembayaran menunggu verifikasi sebelum mengirim ulang.'
              : e is MultigunaPaymentFailure
              ? e.message
              : 'Preview belum dapat dimuat. Coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final rule = options?['amount_rule'] as Map? ?? {};
    final blocked = options?['has_pending_payment'] == true;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Bayar cicilan')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) Text(_error!),
              if (options == null && !_loading)
                TextButton(onPressed: _load, child: const Text('Coba lagi')),
              if (options != null) ...[
                FormValue('Kontrak', '${options['contract']['trx_id']}'),
                const SizedBox(height: 16),
                FormValue('Pembiayaan', '${options['contract']['asset_type']}'),
                const SizedBox(height: 16),
                FormValue(
                  'Sisa kewajiban',
                  rupiah(paymentNumber(options['contract']['outstanding'])),
                ),
                const SizedBox(height: 24),
                if (blocked)
                  const Text(
                    'Kontrak ini memiliki pembayaran yang menunggu verifikasi admin. Periksa pembayaran aktif di halaman Multiguna.',
                  )
                else
                  Form(
                    key: _form,
                    child: AbsorbPointer(
                      absorbing: _busy || _uncertain,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Pilihan pembayaran',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final choices = <(String, int)>[
                                for (final count in [1, 2, 3])
                                  if (paymentNumber(rule['multiple_of']) *
                                          count <=
                                      paymentNumber(rule['maximum']))
                                    (
                                      '$count cicilan',
                                      paymentNumber(rule['multiple_of']) *
                                          count,
                                    ),
                                (
                                  'Lunasi',
                                  paymentNumber(rule['settlement_amount']),
                                ),
                              ];
                              final columns =
                                  constraints.maxWidth /
                                          MediaQuery.textScalerOf(
                                            context,
                                          ).scale(1) <
                                      260
                                  ? 1
                                  : 2;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final choice in choices)
                                    SizedBox(
                                      width:
                                          (constraints.maxWidth -
                                              12 * (columns - 1)) /
                                          columns,
                                      child: Semantics(
                                        selected:
                                            moneyValue(_amount.text) ==
                                            choice.$2,
                                        child: BasyaActionButton(
                                          label: choice.$1,
                                          expand: true,
                                          style:
                                              moneyValue(_amount.text) ==
                                                  choice.$2
                                              ? BasyaActionStyle.tonal
                                              : BasyaActionStyle.secondary,
                                          icon:
                                              moneyValue(_amount.text) ==
                                                  choice.$2
                                              ? Icons.check
                                              : null,
                                          onPressed: () => setState(() {
                                            _amount.text = groupDigits(
                                              '${choice.$2}',
                                            );
                                            _preview = null;
                                          }),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _amount,
                            inputFormatters: [RupiahInputFormatter()],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Nominal pembayaran',
                              prefixText: 'Rp ',
                            ),
                            onChanged: (_) => setState(() => _preview = null),
                            validator: (v) => validateInstallmentAmount(
                              moneyValue(v ?? ''),
                              rule,
                            ),
                          ),
                          const SizedBox(height: 20),
                          BasyaDateField(
                            label: 'Tanggal transfer',
                            pastOnly: true,
                            value: _date,
                            onChanged: (v) => setState(() => _date = v),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<int>(
                            initialValue: _account,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Rekening tujuan',
                            ),
                            items: [
                              for (final bank
                                  in options['bank_accounts'] as List)
                                DropdownMenuItem(
                                  value: paymentNumber(bank['id']),
                                  child: Text(
                                    '${bank['bank_name']} · ${bank['account_no']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) => setState(() => _account = v),
                            validator: (v) =>
                                v == null ? 'Pilih rekening tujuan.' : null,
                          ),
                          for (final bank in options['bank_accounts'] as List)
                            if (bank['id'] == _account)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  'Atas nama ${bank['account_name']}',
                                ),
                              ),
                          const SizedBox(height: 20),
                          BasyaAttachmentField(
                            label: 'Bukti pembayaran',
                            onChanged: (v) => _proof = v,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _note,
                            maxLength: 255,
                            decoration: const InputDecoration(
                              labelText: 'Catatan (opsional)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          BasyaActionButton(
                            label: 'Tinjau pembayaran',
                            style: BasyaActionStyle.emphasis,
                            expand: true,
                            loading: _busy,
                            onPressed: _uncertain ? null : _review,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_uncertain || blocked)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali ke Multiguna'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
