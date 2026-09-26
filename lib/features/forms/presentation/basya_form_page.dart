import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/domain/auth_profile.dart';
import '../../multiguna/domain/multiguna_overview_data.dart';
import '../domain/form_preview.dart';
import 'form_widgets.dart';

/// Interactive local forms. No network calls or account mutations occur here.
class BasyaFormPage extends StatefulWidget {
  const BasyaFormPage({
    super.key,
    required this.kind,
    this.profile,
    this.loan,
    this.attachmentPicker,
  });
  final BasyaFormKind kind;
  final AuthProfile? profile;
  final MultigunaLoan? loan;
  final AttachmentPicker? attachmentPicker;

  @override
  State<BasyaFormPage> createState() => _BasyaFormPageState();
}

class _BasyaFormPageState extends State<BasyaFormPage> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};
  final _textKeys = <String, GlobalKey<FormFieldState<String>>>{};
  final _choices = <String, String>{};
  final _dates = <String, DateTime>{};
  final _files = <String, LocalAttachment>{};
  final _visiblePasswords = <String>{};
  final _moneyFields = <String>{};
  bool _dirty = false;
  bool _allowPop = false;
  bool _leaving = false;
  bool _busy = false;

  BasyaFormKind get _kind => widget.kind;
  MultigunaLoan get _loan =>
      widget.loan ?? MultigunaOverviewData.demo.nearestLoan!;
  TextEditingController _controller(String label) =>
      _controllers.putIfAbsent(label, () => TextEditingController());
  String _value(String label) => _controllers[label]?.text.trim() ?? '';
  int _amount(String label) => moneyValue(_value(label));
  String get _memberName => widget.profile?.displayName ?? 'Anggota Demo';
  String _available(String? value, String demo) => widget.profile == null
      ? demo
      : value == null || value.trim().isEmpty
      ? 'Belum tersedia'
      : value;

  @override
  void initState() {
    super.initState();
    if (_kind == BasyaFormKind.editProfile) {
      final profile = widget.profile;
      _controller('Nama').text = _memberName;
      _controller('Email').text = profile?.email ?? 'anggota@example.com';
      _controller('Nomor telepon').text =
          profile?.nasabah?.contact ?? (profile == null ? '081234567890' : '');
      _controller('Alamat').text = profile == null
          ? 'Jl. Contoh No. 17, Bandung'
          : '';
      _controller('Nama pemilik rekening').text =
          profile?.nasabah?.accountName ??
          (profile == null ? 'Anggota Demo' : '');
      _controller('Nomor rekening').text =
          profile?.nasabah?.accountNumber ??
          (profile == null ? '123456789012' : '');
      final bank = profile?.nasabah?.bankName;
      if (bank != null && bank.isNotEmpty) _choices['Nama bank'] = bank;
      if (profile == null) _choices['Nama bank'] = FormPreview.banks.first;
    }
    if (_kind == BasyaFormKind.installment) {
      _controller('Nominal pembayaran').text = groupDigits(
        _loan.nextAmount.toString(),
      );
      _controller('Urutan cicilan').text = _loan.nextInstallmentNumber
          .toString();
      _choices['Bulan'] = FormPreview.months[_loan.nextDueDate.month - 1];
      _choices['Tahun'] = '${_loan.nextDueDate.year}';
    }
    if (_kind == BasyaFormKind.mandatorySavings) {
      _choices['Bulan'] = FormPreview.months[DateTime.now().month - 1];
      _choices['Tahun'] = '${DateTime.now().year}';
    }
    if (_kind == BasyaFormKind.financing) _controller('Uang muka').text = '0';
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _files.clear();
    super.dispose();
  }

  void _changed() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _exit() async {
    if (_busy || _leaving) return;
    _leaving = true;
    final discard =
        !_dirty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Tinggalkan form?'),
                content: const Text(
                  'Isian dan berkas yang Anda pilih belum disimpan. Jika keluar, perubahan akan hilang.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Lanjutkan mengisi'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Tinggalkan form'),
                  ),
                ],
              ),
            ) ==
            true;
    if (!mounted) return;
    _leaving = false;
    if (!discard) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _review() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      final first = invalid.first;
      await Scrollable.ensureVisible(
        first.context,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        alignment: .15,
      );
      for (final entry in _textKeys.entries) {
        if (entry.value.currentState == first) {
          _focusNodes[entry.key]?.requestFocus();
        }
      }
      return;
    }
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          FormReviewSheet(title: _kind.title, values: _reviewValues()),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    // A short local transition demonstrates submitting without contacting a server.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _busy = false);
    final finish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.task_alt_rounded,
          size: 40,
          color: AppTheme.teal,
        ),
        title: const Text('Pratinjau selesai'),
        content: const Text(
          'Alur form berhasil dicoba. Tidak ada transaksi yang dikirim, saldo yang dipindahkan, atau data akun yang diubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali ke form'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
    if (finish == true && mounted) {
      setState(() {
        _dirty = false;
        _allowPop = true;
      });
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _text(
    String label, {
    String? hint,
    bool optional = false,
    bool money = false,
    bool password = false,
    bool digits = false,
    int lines = 1,
    int? maxAmount,
    bool allowZero = false,
    String? helper,
    String? Function(String)? validate,
    TextInputType? keyboard,
    Iterable<String>? autofill,
  }) {
    if (money) _moneyFields.add(label);
    final controller = _controller(label);
    final focus = _focusNodes.putIfAbsent(label, () => FocusNode());
    final key = _textKeys.putIfAbsent(
      label,
      () => GlobalKey<FormFieldState<String>>(),
    );
    return TextFormField(
      key: key,
      controller: controller,
      focusNode: focus,
      style: const TextStyle(fontSize: 16, height: 1.5, color: AppTheme.ink),
      decoration: formDecoration(
        '$label${optional ? ' (opsional)' : ''}',
        hint: hint ?? 'Masukkan ${label.toLowerCase()}',
        helper: helper,
        prefix: money ? 'Rp ' : null,
        suffix: password
            ? IconButton(
                tooltip: _visiblePasswords.contains(label)
                    ? 'Sembunyikan $label'
                    : 'Tampilkan $label',
                onPressed: () => setState(() {
                  if (!_visiblePasswords.add(label)) {
                    _visiblePasswords.remove(label);
                  }
                }),
                icon: Icon(
                  _visiblePasswords.contains(label)
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.teal,
                ),
              )
            : null,
      ),
      keyboardType: money || digits
          ? TextInputType.number
          : keyboard ??
                (lines > 1 ? TextInputType.multiline : TextInputType.text),
      inputFormatters: [
        if (money) RupiahInputFormatter(),
        if (digits) FilteringTextInputFormatter.digitsOnly,
        if (!money && !password)
          LengthLimitingTextInputFormatter(lines > 1 ? 1000 : 150),
      ],
      maxLines: lines,
      obscureText: password && !_visiblePasswords.contains(label),
      autocorrect: !password && !money && !digits,
      enableSuggestions: !password,
      autofillHints: autofill,
      textInputAction: lines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      onChanged: (_) {
        _changed();
        if (_kind == BasyaFormKind.financing && money) setState(() {});
      },
      validator: (raw) {
        final value = password ? raw ?? '' : raw?.trim() ?? '';
        if (value.isEmpty) {
          return optional ? null : 'Isi ${label.toLowerCase()}.';
        }
        if (money) {
          final amount = moneyValue(value);
          if (!allowZero && amount <= 0) {
            return 'Masukkan nominal lebih dari Rp 0.';
          }
          if (maxAmount != null && amount > maxAmount) {
            return 'Nominal maksimal ${rupiah(maxAmount)}.';
          }
        }
        return validate?.call(value);
      },
    );
  }

  Widget _choice(String label, List<String> options, {String? helper}) =>
      BasyaChoiceField(
        key: ValueKey(label),
        label: label,
        options: options,
        helper: helper,
        value: _choices[label],
        onChanged: (value) => setState(() {
          _choices[label] = value;
          _dirty = true;
        }),
      );
  Widget _date(String label, {bool pastOnly = false}) => BasyaDateField(
    key: ValueKey(label),
    label: label,
    value: _dates[label],
    pastOnly: pastOnly,
    onChanged: (value) => setState(() {
      _dates[label] = value;
      _dirty = true;
    }),
  );
  Widget _file(
    String label, {
    bool pdfOnly = false,
    bool imageOnly = false,
    bool required = true,
  }) => BasyaAttachmentField(
    key: ValueKey(label),
    label: label,
    pdfOnly: pdfOnly,
    imageOnly: imageOnly,
    required: required,
    picker: widget.attachmentPicker,
    onChanged: (value) => setState(() {
      if (value == null) {
        _files.remove(label);
      } else {
        _files[label] = value;
      }
      _dirty = true;
    }),
  );
  List<String> get _years {
    final current = DateTime.now().year;
    return {
      for (var year = current - 5; year <= current + 5; year++) '$year',
      if (_choices['Tahun'] != null) _choices['Tahun']!,
    }.toList()..sort();
  }

  List<Widget> _period() => [
    _choice('Bulan', FormPreview.months),
    _choice('Tahun', _years),
  ];
  List<Widget> _paymentDestination() => [
    const FormValue('Metode pembayaran', 'Transfer manual'),
    _choice(
      'Rekening tujuan',
      FormPreview.cooperativeAccounts,
      helper: 'Rekening contoh untuk pratinjau. Jangan melakukan transfer.',
    ),
    if (_choices['Rekening tujuan'] != null)
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: _choices['Rekening tujuan']!.split(' · ')[1]),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nomor rekening contoh disalin.')),
              );
            }
          },
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: const Text('Salin nomor rekening contoh'),
        ),
      ),
  ];

  List<Widget> _payment() => [
    const FormNotice(
      'Pembayaran menunggu verifikasi admin.',
      title: 'Transfer manual',
    ),
    _date('Tanggal transfer', pastOnly: true),
    if (_kind == BasyaFormKind.mandatorySavings) ...[
      const FormSection('Periode iuran'),
      ..._period(),
      FormValue(
        'Nominal kewajiban · contoh',
        rupiah(FormPreview.mandatoryAmount),
        prominent: true,
      ),
    ] else
      _text('Nominal', money: true),
    ..._paymentDestination(),
    _file('Bukti pembayaran'),
    const Text(
      'Pengiriman bukti tidak berarti pembayaran telah disahkan.',
      style: TextStyle(fontSize: 13, height: 1.5, color: AppTheme.muted),
    ),
  ];

  List<Widget> _withdraw() => [
    FormValue(
      'Saldo Sukarela tersedia · contoh',
      rupiah(FormPreview.savings),
      prominent: true,
    ),
    const FormSection(
      'Data penerima',
      subtitle:
          'Data rekening ditampilkan sebagai informasi. Perubahan rekening dilakukan melalui Edit Profil.',
    ),
    const FormValue('Nomor identitas · contoh', '3273••••••••0187'),
    FormValue(
      'Kontak',
      _available(widget.profile?.nasabah?.contact, '0812••••5678'),
    ),
    FormValue(
      'Nomor rekening',
      _available(widget.profile?.nasabah?.accountNumber, '1234 5678 9012'),
    ),
    FormValue(
      'Bank',
      _available(widget.profile?.nasabah?.bankName, 'Bank Mandiri'),
    ),
    FormValue(
      'Nama pemilik rekening',
      _available(widget.profile?.nasabah?.accountName, 'Anggota Demo'),
    ),
    _text('Nilai penarikan', money: true, maxAmount: FormPreview.savings),
    _text(
      'Catatan',
      optional: true,
      lines: 3,
      hint: 'Tulis catatan jika diperlukan',
    ),
    const FormNotice('Penarikan menunggu verifikasi admin.', warning: true),
  ];

  List<Widget> _mutation() => [
    FormValue(
      'Buy Power tersedia · contoh',
      rupiah(FormPreview.buyPower),
      prominent: true,
    ),
    _text('Nominal mutasi', money: true, maxAmount: FormPreview.buyPower),
    const FormSection('Ringkasan'),
    const FormValue('Dari', 'Buy Power'),
    const FormValue('Ke', 'Simpanan Sukarela'),
    const FormNotice(
      'Mutasi internal tidak membutuhkan bukti transfer. Biaya Rp 0 pada pratinjau ini.',
    ),
  ];

  List<Widget> _installment() => [
    FormValue('Kontrak', _loan.contractNumber),
    FormValue(
      'Cicilan per bulan',
      rupiah(_loan.installmentAmount),
      prominent: true,
    ),
    _text('Nominal pembayaran', money: true, maxAmount: _loan.remainingBalance),
    _date('Tanggal uang masuk', pastOnly: true),
    _text(
      'Urutan cicilan',
      digits: true,
      hint: 'Contoh: 4',
      validate: (value) {
        final number = int.tryParse(value) ?? 0;
        return number < 1 || number > _loan.totalInstallments
            ? 'Isi urutan cicilan 1–${_loan.totalInstallments}.'
            : null;
      },
    ),
    ..._period(),
    ..._paymentDestination(),
    _text('Catatan', optional: true, lines: 3),
    _file('Bukti pembayaran'),
    const FormNotice(
      'Nominal dapat disesuaikan untuk beberapa cicilan atau pelunasan lebih awal. Status pembayaran mengikuti verifikasi admin.',
      warning: true,
    ),
  ];

  int get _principal => (_amount('Harga penawaran') - _amount('Uang muka'))
      .clamp(0, 999999999999);
  int get _months =>
      int.tryParse(_choices['Jangka waktu']?.split(' ').first ?? '') ?? 0;
  bool get _quoteReady =>
      _principal > 0 &&
      _principal <= FormPreview.financingLimit &&
      _months > 0 &&
      _amount('Uang muka') <= _amount('Harga penawaran');
  int get _demoMargin => (_principal * .10).round();

  List<Widget> _financing() => [
    FormValue(
      'Limit tersedia · contoh',
      rupiah(FormPreview.financingLimit),
      prominent: true,
    ),
    const FormSection(
      'Detail pembiayaan',
      subtitle: 'Plafon pengajuan adalah harga penawaran dikurangi uang muka.',
    ),
    _choice('Tujuan pembiayaan', [
      'Pembelian kendaraan',
      'Renovasi rumah',
      'Peralatan usaha',
      'Kebutuhan lainnya',
    ]),
    _text('Jenis aset pembiayaan', hint: 'Contoh: sepeda motor'),
    _text('Harga penawaran', money: true),
    _text(
      'Uang muka',
      money: true,
      allowZero: true,
      validate: (_) {
        if (_amount('Uang muka') >= _amount('Harga penawaran')) {
          return 'Uang muka harus lebih kecil dari harga penawaran.';
        }
        if (_principal > FormPreview.financingLimit) {
          return 'Sesuaikan harga atau uang muka agar plafon maksimal ${rupiah(FormPreview.financingLimit)}.';
        }
        return null;
      },
    ),
    FormValue(
      'Plafon pengajuan',
      _value('Harga penawaran').isEmpty ? '—' : rupiah(_principal),
    ),
    _choice('Jangka waktu', [
      '3 bulan',
      '6 bulan',
      '12 bulan',
      '18 bulan',
      '24 bulan',
    ]),
    const FormSection(
      'Simulasi dari Basya',
      subtitle:
          'Simulasi contoh: margin 10% dari plafon dan administrasi Rp 50.000. Hanya ilustrasi, bukan penawaran pembiayaan.',
    ),
    FormValue('Margin Basya · contoh', _quoteReady ? rupiah(_demoMargin) : '—'),
    FormValue(
      'Harga jual Basya · contoh',
      _quoteReady ? rupiah(_principal + _demoMargin) : '—',
    ),
    FormValue(
      'Estimasi cicilan per bulan · contoh',
      _quoteReady ? rupiah(((_principal + _demoMargin) / _months).ceil()) : '—',
    ),
    FormValue('Biaya administrasi · contoh', _quoteReady ? rupiah(50000) : '—'),
    const FormSection('Informasi supplier'),
    _text('Nama supplier'),
    _text(
      'Nomor telepon supplier',
      keyboard: TextInputType.phone,
      validate: _phoneValidator,
    ),
    const FormSection(
      'Data jaminan',
      subtitle: 'Pastikan informasi sesuai berkas kepemilikan.',
    ),
    _text('Jenis jaminan', hint: 'Contoh: BPKB kendaraan'),
    _text('Alamat jaminan', lines: 3),
    _choice('Status kepemilikan', [
      'Milik sendiri',
      'Milik pasangan',
      'Milik keluarga',
      'Lainnya',
    ]),
    _date('Berlaku hingga'),
    _text('Nomor sertifikat / jaminan'),
    _text('Kondisi jaminan', lines: 3),
    const FormSection('Penagihan'),
    _date('Awal penagihan'),
    _choice('Tanggal jatuh tempo', [
      for (var day = 1; day <= 31; day++) '$day',
    ]),
    _file('Berkas akad', pdfOnly: true),
  ];

  String? _phoneValidator(String value) =>
      RegExp(r'^\+?[0-9 ()-]+$').hasMatch(value) &&
          value.replaceAll(RegExp(r'[^0-9]'), '').length >= 8 &&
          value.replaceAll(RegExp(r'[^0-9]'), '').length <= 15
      ? null
      : 'Masukkan nomor telepon yang dapat dihubungi, contoh 081234567890.';

  List<Widget> _editProfile() => [
    Center(
      child: CircleAvatar(
        radius: 38,
        backgroundColor: AppTheme.neutralSurface,
        child: _files['Foto profil'] != null
            ? ClipOval(
                child: Image.memory(
                  _files['Foto profil']!.bytes,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.person_outline, color: AppTheme.teal),
                ),
              )
            : Text(
                _memberName.characters.first.toUpperCase(),
                style: const TextStyle(fontSize: 28, color: AppTheme.teal),
              ),
      ),
    ),
    _file('Foto profil', imageOnly: true, required: false),
    _text('Nama', autofill: const [AutofillHints.name]),
    _text(
      'Email',
      keyboard: TextInputType.emailAddress,
      autofill: const [AutofillHints.email],
      validate: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)
          ? null
          : 'Masukkan email lengkap, contoh nama@example.com.',
    ),
    _text(
      'Nomor telepon',
      keyboard: TextInputType.phone,
      validate: _phoneValidator,
      autofill: const [AutofillHints.telephoneNumber],
    ),
    _text(
      'Alamat',
      lines: 3,
      autofill: const [AutofillHints.fullStreetAddress],
    ),
    const FormSection(
      'Informasi rekening bank',
      subtitle: 'Digunakan untuk pencairan dana.',
    ),
    _choice(
      'Nama bank',
      {
        ...FormPreview.banks,
        if (_choices['Nama bank'] != null) _choices['Nama bank']!,
      }.toList(),
    ),
    _text('Nama pemilik rekening'),
    _text(
      'Nomor rekening',
      digits: true,
      validate: (value) =>
          value.length < 5 ? 'Periksa kembali nomor rekening Anda.' : null,
    ),
    const FormNotice(
      'Perubahan rekening mungkin memerlukan verifikasi admin.',
      warning: true,
    ),
  ];

  List<Widget> _password() => [
    const FormNotice(
      'Kata sandi disembunyikan secara default. Gunakan tombol mata untuk memeriksa isian.',
      title: 'Keamanan akun',
    ),
    _text(
      'Kata sandi lama',
      password: true,
      autofill: const [AutofillHints.password],
    ),
    _text(
      'Kata sandi baru',
      password: true,
      autofill: const [AutofillHints.newPassword],
      helper: 'Untuk demo, gunakan minimal 8 karakter.',
      validate: (value) {
        if (value.length < 8) return 'Gunakan minimal 8 karakter.';
        if (value == _controllers['Kata sandi lama']?.text) {
          return 'Gunakan kata sandi yang berbeda dari kata sandi lama.';
        }
        return null;
      },
    ),
    _text(
      'Konfirmasi kata sandi baru',
      password: true,
      autofill: const [AutofillHints.newPassword],
      validate: (value) => value == _controllers['Kata sandi baru']?.text
          ? null
          : 'Konfirmasi harus sama dengan kata sandi baru.',
    ),
  ];

  Map<String, String> _reviewValues() {
    if (_kind == BasyaFormKind.password) {
      return {
        'Keamanan akun':
            'Kata sandi baru dan konfirmasi cocok. Isian kata sandi tidak ditampilkan pada ringkasan.',
      };
    }
    return {
      if (_kind == BasyaFormKind.withdraw) ...{
        'Nama penerima': _available(
          widget.profile?.nasabah?.accountName,
          'Anggota Demo',
        ),
        'Bank': _available(widget.profile?.nasabah?.bankName, 'Bank Mandiri'),
        'Nomor rekening': _available(
          widget.profile?.nasabah?.accountNumber,
          '1234 5678 9012',
        ),
      },
      if (_kind == BasyaFormKind.mutation) ...{
        'Dari': 'Buy Power',
        'Ke': 'Simpanan Sukarela',
        'Biaya · contoh': rupiah(0),
      },
      if (_kind == BasyaFormKind.installment) 'Kontrak': _loan.contractNumber,
      if (_kind == BasyaFormKind.mandatorySavings)
        'Nominal kewajiban · contoh': rupiah(FormPreview.mandatoryAmount),
      for (final entry in _controllers.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: _moneyFields.contains(entry.key)
              ? rupiah(_amount(entry.key))
              : entry.value.text,
      ..._choices,
      for (final entry in _dates.entries)
        entry.key:
            '${entry.value.day} ${FormPreview.months[entry.value.month - 1]} ${entry.value.year}',
      if (_kind == BasyaFormKind.financing) ...{
        'Plafon pengajuan': rupiah(_principal),
        'Margin · contoh': rupiah(_demoMargin),
        'Harga jual · contoh': rupiah(_principal + _demoMargin),
        'Cicilan per bulan · contoh': rupiah(
          ((_principal + _demoMargin) / _months).ceil(),
        ),
        'Administrasi · contoh': rupiah(50000),
      },
      for (final entry in _files.entries) entry.key: entry.value.name,
    };
  }

  String get _action => switch (_kind) {
    BasyaFormKind.withdraw => 'Tinjau penarikan',
    BasyaFormKind.mutation => 'Lanjutkan mutasi',
    BasyaFormKind.financing => 'Tinjau pengajuan',
    BasyaFormKind.editProfile => 'Tinjau perubahan',
    BasyaFormKind.password => 'Tinjau perubahan password',
    _ => 'Tinjau pembayaran',
  };

  @override
  Widget build(BuildContext context) {
    final children = switch (_kind) {
      BasyaFormKind.topUpSavings ||
      BasyaFormKind.topUpBuyPower ||
      BasyaFormKind.mandatorySavings => _payment(),
      BasyaFormKind.withdraw => _withdraw(),
      BasyaFormKind.mutation => _mutation(),
      BasyaFormKind.installment => _installment(),
      BasyaFormKind.financing => _financing(),
      BasyaFormKind.editProfile => _editProfile(),
      BasyaFormKind.password => _password(),
    };
    return PopScope<Object?>(
      canPop: _allowPop || (!_dirty && !_busy),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: AppTheme.loginCanvas,
        appBar: AppBar(
          backgroundColor: AppTheme.loginCanvas,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _busy ? null : _exit,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            _kind.title,
            maxLines: 2,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          toolbarHeight: MediaQuery.textScalerOf(
            context,
          ).scale(56).clamp(56, 120),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AbsorbPointer(
                absorbing: _busy,
                child: Form(
                  key: _form,
                  onChanged: _changed,
                  child: SingleChildScrollView(
                    key: const ValueKey('basya-form-scroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.sizeOf(context).width <= 360 ? 16 : 20,
                      12,
                      MediaQuery.sizeOf(context).width <= 360 ? 16 : 20,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _kind.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Mode demo · Tidak ada perubahan akun atau transaksi.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppTheme.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 28),
                        for (final child in children) ...[
                          child,
                          const SizedBox(height: 24),
                        ],
                        const SizedBox(height: 8),
                        BasyaActionButton(
                          key: const ValueKey('review-form'),
                          label: _busy ? 'Memproses demo…' : _action,
                          onPressed: _review,
                          loading: _busy,
                          labelSize: 16,
                          style: BasyaActionStyle.emphasis,
                          expand: true,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Periksa isian pada ringkasan sebelum konfirmasi.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppTheme.muted,
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
      ),
    );
  }
}
