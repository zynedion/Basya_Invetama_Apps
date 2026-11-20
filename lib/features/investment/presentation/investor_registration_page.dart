import '../../forms/domain/form_preview.dart'
    show RupiahInputFormatter, moneyValue, groupDigits;
import '../data/investor_registration_api.dart';
import '../../auth/domain/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../../core/widgets/module_page_header.dart';
import '../../auth/domain/auth_profile.dart';

class InvestorRegistrationIntro extends StatefulWidget {
  const InvestorRegistrationIntro({super.key, this.profile, this.session});
  final AuthProfile? profile;
  final AuthSession? session;
  @override
  State<InvestorRegistrationIntro> createState() => _RegistrationIntroState();
}

class _RegistrationIntroState extends State<InvestorRegistrationIntro> {
  final _api = InvestorRegistrationApi();
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading && _data != null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.session == null) {
        throw const RegistrationFailure('Silakan masuk untuk mendaftar.', 401);
      }
      final data = await _api.load(widget.session!);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is RegistrationFailure
              ? e.message
              : 'Status belum dapat dimuat. Periksa koneksi Anda.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final state = _data?['registration']?['state'];
    final canApply =
        _data?['eligibility']?['can_apply'] == true &&
        state == 'not_registered';
    if (_error != null || !canApply) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 150),
          children: [
            const ModulePageHeader(
              title: 'Investasi',
              subtitle: 'Status pendaftaran investor',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralSurface,
                        borderRadius: BorderRadius.circular(
                          AppTheme.controlRadius,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status belum dapat diperbarui',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                          if (_data != null)
                            const Text(
                              'Status terakhir ditampilkan di bawah.',
                              style: TextStyle(color: AppTheme.muted),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_data != null && !canApply)
                    _RegistrationStatusCard(data: _data!),
                  const SizedBox(height: 20),
                  BasyaActionButton(
                    label: _error == null ? 'Periksa status' : 'Coba lagi',
                    icon: Icons.refresh,
                    expand: true,
                    loading: _loading,
                    onPressed: _load,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tarik ke bawah untuk memperbarui status.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _RegistrationWelcome(
      onRegister: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => InvestorRegistrationForm(
              profile: widget.profile,
              session: widget.session!,
              data: _data!,
              api: _api,
            ),
          ),
        );
        if (mounted) await _load();
      },
    );
  }
}

class _RegistrationStatusCard extends StatelessWidget {
  const _RegistrationStatusCard({required this.data});
  final Map<String, dynamic> data;

  String? _date(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) return null;
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = data['registration']?['state'];
    final (title, badge, message, icon, color, surface, tone) = switch (state) {
      'not_registered' when data['eligibility']?['can_apply'] == true => (
        'Belum terdaftar',
        'Belum mendaftar',
        'Anda belum mengajukan pendaftaran investor. Lengkapi data diri untuk memulai.',
        Icons.person_add_alt_1_outlined,
        AppTheme.teal,
        AppTheme.neutralSurface,
        BasyaStatusTone.neutral,
      ),
      'pending' => (
        'Menunggu verifikasi',
        'Dalam proses',
        'Pendaftaran Anda sudah diterima dan sedang diperiksa.',
        Icons.hourglass_top_rounded,
        AppTheme.warning,
        AppTheme.warningSurface,
        BasyaStatusTone.warning,
      ),
      'approved' => (
        'Pendaftaran disetujui',
        'Disetujui',
        'Anda telah terdaftar sebagai investor. Masuk kembali untuk memperbarui akses investasi.',
        Icons.check_circle_outline_rounded,
        AppTheme.positive,
        AppTheme.successSurface,
        BasyaStatusTone.success,
      ),
      'inactive' => (
        'Keanggotaan tidak aktif',
        'Tidak aktif',
        'Hubungi pengelola untuk informasi mengenai keanggotaan investor Anda.',
        Icons.pause_circle_outline_rounded,
        AppTheme.muted,
        AppTheme.readOnlySurface,
        BasyaStatusTone.neutral,
      ),
      _ => (
        'Pendaftaran belum tersedia',
        'Belum tersedia',
        data['eligibility']?['reason']?.toString() ??
            'Akun Anda belum memenuhi persyaratan pendaftaran investor.',
        Icons.info_outline_rounded,
        AppTheme.warning,
        AppTheme.warningSurface,
        BasyaStatusTone.warning,
      ),
    };
    final reference = data['registration']?['reg_id']?.toString().trim();
    final date = _date(data['registration']?['submitted_at']);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              if (state == 'inactive')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.readOnlySurface,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                BasyaStatusBadge(text: badge, tone: tone),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppTheme.muted, height: 1.5),
          ),
          if (reference != null && reference.isNotEmpty || date != null) ...[
            const SizedBox(height: 24),
            if (reference != null && reference.isNotEmpty)
              _detail('Nomor pendaftaran', reference),
            if (date != null) ...[
              if (reference != null && reference.isNotEmpty)
                const SizedBox(height: 16),
              _detail('Diajukan pada', date),
            ],
          ],
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: AppTheme.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _RegistrationWelcome extends StatelessWidget {
  const _RegistrationWelcome({required this.onRegister});
  final VoidCallback onRegister;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: 150),
    children: [
      const ModulePageHeader(
        title: 'Investasi',
        subtitle: 'Mulai dengan melengkapi profil investor.',
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.heroRadius),
                gradient: const LinearGradient(
                  colors: [Color(0xFF004E50), Color(0xFF008579)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BasyaStatusBadge(
                      text: 'Belum terdaftar',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mulai investasi bersama Basya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lengkapi profil Anda untuk mendaftar sebagai investor.',
                    style: TextStyle(color: Color(0xFFD8EFEB), height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  BasyaActionButton(
                    label: 'Daftar menjadi investor',
                    style: BasyaActionStyle.secondary,
                    expand: true,
                    onPressed: onRegister,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pendaftaran tidak langsung melakukan pembelian investasi.',
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 28),
            const Text(
              'Tiga langkah sederhana',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            for (final step in const [
              (
                Icons.person_outline,
                'Lengkapi profil',
                'Siapkan identitas, NPWP, dan informasi keuangan.',
              ),
              (
                Icons.fact_check_outlined,
                'Kirim pendaftaran',
                'Periksa data dan konfirmasi pengiriman.',
              ),
              (
                Icons.hourglass_top,
                'Pantau status',
                'Lihat perkembangan pendaftaran di tab Investasi.',
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(step.$1, color: AppTheme.teal),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.$2,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.$3,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class InvestorRegistrationForm extends StatefulWidget {
  const InvestorRegistrationForm({
    super.key,
    this.profile,
    required this.session,
    required this.data,
    required this.api,
  });
  final AuthSession session;
  final Map<String, dynamic> data;
  final InvestorRegistrationApi api;
  final AuthProfile? profile;
  @override
  State<InvestorRegistrationForm> createState() =>
      _InvestorRegistrationFormState();
}

class _InvestorRegistrationFormState extends State<InvestorRegistrationForm> {
  final _form = GlobalKey<FormState>();
  static const _groups = [
    [
      'Nama anggota',
      'Nomor KTP',
      'Nomor kontak',
      'Tempat lahir',
      'Tanggal lahir',
    ],
    ['Alamat', 'Nomor NPWP', 'Nama ibu kandung'],
    ['Pekerjaan', 'Pendapatan', 'Sumber dana', 'Pendidikan terakhir'],
  ];
  static const _titles = ['Identitas', 'Data pribadi', 'Profil keuangan'];
  late final Map<String, TextEditingController> _fields;
  DateTime? _birth;
  int? _job;
  int? _graduate;
  List<Map<String, dynamic>> _options(String key) =>
      ((widget.data['options']?[key] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['id'] is int)
          .toList();
  @override
  void initState() {
    super.initState();
    _fields = {
      for (final key in _groups.expand((g) => g)) key: TextEditingController(),
    };
    _fields['Nama anggota']!.text = widget.profile?.displayName ?? '';
    _fields['Nomor kontak']!.text = widget.profile?.nasabah?.contact ?? '';
    final prefill = widget.data['prefill'] as Map? ?? {};
    const keys = {
      'Nama anggota': 'fullname',
      'Nomor KTP': 'identity_id',
      'Nomor kontak': 'contact',
      'Tempat lahir': 'pob',
      'Alamat': 'address',
      'Nomor NPWP': 'tax_id',
      'Nama ibu kandung': 'mother_name',
      'Pendapatan': 'income',
      'Sumber dana': 'source_funds',
    };
    for (final entry in keys.entries) {
      if (prefill[entry.value] != null) {
        _fields[entry.key]!.text = entry.key == 'Pendapatan'
            ? groupDigits(prefill[entry.value].toString())
            : prefill[entry.value].toString();
      }
    }
    _birth = DateTime.tryParse(prefill['bod']?.toString() ?? '');
    if (_birth != null) {
      _fields['Tanggal lahir']!.text =
          '${_birth!.day.toString().padLeft(2, '0')}/${_birth!.month.toString().padLeft(2, '0')}/${_birth!.year}';
    }
    final job = prefill['jobs'];
    if (job is Map && _options('jobs').any((e) => e['id'] == job['id'])) {
      _job = job['id'] as int;
      _fields['Pekerjaan']!.text = job['name'].toString();
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Tanggal lahir',
    );
    if (value != null && mounted) {
      setState(() {
        _birth = value;
        _fields['Tanggal lahir']!.text =
            '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
      });
    }
  }

  String? _validate(String label, String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return '$label wajib diisi';
    if (label == 'Alamat' && value.length > 50) {
      return 'Alamat maksimal 50 karakter';
    }
    if (label == 'Nomor KTP' && !RegExp(r'^\d{16}$').hasMatch(value)) {
      return 'Masukkan 16 digit nomor KTP';
    }
    if (label == 'Nomor kontak' && !RegExp(r'^\+?\d{9,15}$').hasMatch(value)) {
      return 'Masukkan nomor kontak yang valid';
    }
    if (label == 'Pendapatan' &&
        (!RegExp(r'^\d+(\.\d{3})*$').hasMatch(value))) {
      return 'Masukkan nominal pendapatan yang valid';
    }
    return null;
  }

  Widget _dropdown(String label) {
    final isJob = label == 'Pekerjaan';
    final options = _options(isJob ? 'jobs' : 'graduate');
    return DropdownButtonFormField<int>(
      initialValue: isJob ? _job : _graduate,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        helperText: options.isEmpty ? 'Pilihan belum tersedia.' : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: options
          .map(
            (e) => DropdownMenuItem<int>(
              value: e['id'] as int,
              child: Text(e['name'].toString()),
            ),
          )
          .toList(),
      onChanged: options.isEmpty
          ? null
          : (value) => setState(() {
              if (isJob) {
                _job = value;
              } else {
                _graduate = value;
              }
              _fields[label]!.text = options
                  .firstWhere((e) => e['id'] == value)['name']
                  .toString();
            }),
      validator: (value) =>
          value == null ? 'Pilih ${label.toLowerCase()}' : null,
    );
  }

  bool _sending = false;
  String? _error;
  bool _confirming = false;
  Future<void> _submit() async {
    if (_sending || _confirming || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _confirming = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim pendaftaran?'),
        content: const Text(
          'Pastikan data sudah benar. Pendaftaran akan dikirim untuk diverifikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Periksa lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (confirmed != true || !mounted || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      // Check current status before submitting, including after an uncertain result.
      final latest = await widget.api.load(widget.session);
      if (latest['eligibility']?['can_apply'] != true ||
          latest['registration']?['state'] != 'not_registered') {
        if (mounted) {
          setState(() => _sending = false);
          Navigator.pop(context);
        }
        return;
      }
      await widget.api.submit(widget.session, {
        'identity_id': _fields['Nomor KTP']!.text.trim(),
        'contact': _fields['Nomor kontak']!.text.trim(),
        'pob': _fields['Tempat lahir']!.text.trim(),
        'bod':
            '${_birth!.year.toString().padLeft(4, '0')}-${_birth!.month.toString().padLeft(2, '0')}-${_birth!.day.toString().padLeft(2, '0')}',
        'address': _fields['Alamat']!.text.trim(),
        'tax_id': _fields['Nomor NPWP']!.text.trim(),
        'mother_name': _fields['Nama ibu kandung']!.text.trim(),
        'jobs': _job,
        'income': moneyValue(_fields['Pendapatan']!.text),
        'source_funds': _fields['Sumber dana']!.text.trim(),
        'graduate': _graduate,
      });
      if (mounted) {
        setState(() => _sending = false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      if (e is RegistrationFailure && e.status == 409) {
        setState(() => _sending = false);
        Navigator.pop(context);
        return;
      }
      setState(
        () => _error = e is RegistrationFailure
            ? e.message
            : 'Hasil pengiriman belum dapat dipastikan. Periksa koneksi dan status pendaftaran sebelum mencoba kembali.',
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.loginCanvas,
    appBar: AppBar(title: const Text('Daftar investor')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Lengkapi data berikut. Semua kolom wajib diisi.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                for (var group = 0; group < _groups.length; group++) ...[
                  const SizedBox(height: 28),
                  Text(
                    '0${group + 1}  ${_titles[group]}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  for (final label in _groups[group])
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child:
                          ['Pekerjaan', 'Pendidikan terakhir'].contains(label)
                          ? _dropdown(label)
                          : TextFormField(
                              controller: _fields[label],
                              readOnly:
                                  label == 'Nama anggota' ||
                                  label == 'Tanggal lahir',
                              onTap: label == 'Tanggal lahir'
                                  ? _pickDate
                                  : null,
                              validator: (value) => _validate(label, value),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              maxLines: label == 'Alamat' ? 3 : 1,
                              keyboardType:
                                  [
                                    'Nomor KTP',
                                    'Nomor NPWP',
                                    'Pendapatan',
                                  ].contains(label)
                                  ? TextInputType.number
                                  : label == 'Nomor kontak'
                                  ? TextInputType.phone
                                  : TextInputType.text,
                              inputFormatters: label == 'Pendapatan'
                                  ? [RupiahInputFormatter()]
                                  : ['Nomor KTP'].contains(label)
                                  ? [
                                      FilteringTextInputFormatter.digitsOnly,
                                      if (label == 'Nomor KTP')
                                        LengthLimitingTextInputFormatter(16),
                                    ]
                                  : null,
                              decoration: InputDecoration(
                                labelText: label,
                                hintText: label == 'Tanggal lahir'
                                    ? 'Pilih tanggal lahir'
                                    : 'Masukkan ${label.toLowerCase()}',
                                prefixText: label == 'Pendapatan'
                                    ? 'Rp '
                                    : null,
                                helperText: label == 'Nama anggota'
                                    ? 'Terisi otomatis dari akun yang sedang login.'
                                    : [
                                        'Pekerjaan',
                                        'Pendidikan terakhir',
                                      ].contains(label)
                                    ? 'Isi sementara; pilihan resmi belum tersedia.'
                                    : null,
                                helperMaxLines: 2,
                                suffixIcon: label == 'Nama anggota'
                                    ? const Icon(Icons.lock_outline)
                                    : label == 'Tanggal lahir'
                                    ? const Icon(Icons.calendar_month_outlined)
                                    : null,
                                filled: true,
                                fillColor: label == 'Nama anggota'
                                    ? AppTheme.neutralSurface
                                    : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Anda dapat memeriksa kembali seluruh data sebelum mengirim pendaftaran.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                BasyaActionButton(
                  label: _sending ? 'Mengirim...' : 'Kirim pendaftaran',
                  style: BasyaActionStyle.emphasis,
                  loading: _sending,
                  expand: true,
                  onPressed: _sending ? null : _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
