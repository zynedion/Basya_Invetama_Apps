import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../../core/widgets/module_page_header.dart';
import '../../auth/domain/auth_profile.dart';

class InvestorRegistrationIntro extends StatelessWidget {
  const InvestorRegistrationIntro({super.key, this.profile});
  final AuthProfile? profile;
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
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [Color(0xFF004E50), Color(0xFF008579)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MENJADI INVESTOR BASYA',
                    style: TextStyle(
                      color: Color(0xFFBFFFE8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Langkah awal untuk berinvestasi bersama.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Lengkapi data diri agar Anda dapat melanjutkan pendaftaran sebagai investor.',
                    style: TextStyle(color: Color(0xFFD8EFEB), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                'Tinjau data',
                'Periksa kembali data sebelum mengirim pendaftaran.',
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
            const SizedBox(height: 28),
            BasyaActionButton(
              label: 'Daftar menjadi investor',
              expand: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InvestorRegistrationForm(profile: profile),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pendaftaran tidak langsung melakukan pembelian investasi.',
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

class InvestorRegistrationForm extends StatefulWidget {
  const InvestorRegistrationForm({super.key, this.profile});
  final AuthProfile? profile;
  @override
  State<InvestorRegistrationForm> createState() =>
      _InvestorRegistrationFormState();
}

class _InvestorRegistrationFormState extends State<InvestorRegistrationForm> {
  final _form = GlobalKey<FormState>();
  final _sections = [GlobalKey(), GlobalKey(), GlobalKey()];
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
  @override
  void initState() {
    super.initState();
    _fields = {
      for (final key in _groups.expand((g) => g)) key: TextEditingController(),
    };
    _fields['Nama anggota']!.text = widget.profile?.displayName ?? '';
    _fields['Nomor kontak']!.text = widget.profile?.nasabah?.contact ?? '';
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
    if (label == 'Nomor KTP' && !RegExp(r'^\d{16}$').hasMatch(value)) {
      return 'Masukkan 16 digit nomor KTP';
    }
    if (label == 'Nomor kontak' && !RegExp(r'^\+?\d{9,15}$').hasMatch(value)) {
      return 'Masukkan nomor kontak yang valid';
    }
    if (label == 'Pendapatan' &&
        (int.tryParse(value) == null || int.parse(value) < 0)) {
      return 'Masukkan nominal pendapatan yang valid';
    }
    return null;
  }

  Future<void> _review() async {
    if (!_form.currentState!.validate()) return;
    final edit = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => _RegistrationReview(
          groups: _groups,
          titles: _titles,
          values: {
            for (final entry in _fields.entries)
              entry.key: entry.value.text.trim(),
          },
        ),
      ),
    );
    if (mounted && edit != null && _sections[edit].currentContext != null) {
      await Scrollable.ensureVisible(
        _sections[edit].currentContext!,
        duration: const Duration(milliseconds: 250),
      );
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
                    key: _sections[group],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  for (final label in _groups[group])
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: TextFormField(
                        controller: _fields[label],
                        readOnly:
                            label == 'Nama anggota' || label == 'Tanggal lahir',
                        onTap: label == 'Tanggal lahir' ? _pickDate : null,
                        validator: (value) => _validate(label, value),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        inputFormatters:
                            ['Nomor KTP', 'Pendapatan'].contains(label)
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
                          prefixText: label == 'Pendapatan' ? 'Rp ' : null,
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
                BasyaActionButton(
                  label: 'Tinjau pendaftaran',
                  expand: true,
                  onPressed: _review,
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

class _RegistrationReview extends StatelessWidget {
  const _RegistrationReview({
    required this.groups,
    required this.titles,
    required this.values,
  });
  final List<List<String>> groups;
  final List<String> titles;
  final Map<String, String> values;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.loginCanvas,
    appBar: AppBar(title: const Text('Tinjau pendaftaran')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Pastikan data Anda sudah benar sebelum dikirim.',
                style: TextStyle(color: AppTheme.muted),
              ),
              for (var index = 0; index < groups.length; index++) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titles[index],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, index),
                      child: const Text('Ubah'),
                    ),
                  ],
                ),
                for (final label in groups[index])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${label == 'Pendapatan' ? 'Rp ' : ''}${values[label]}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
              ],
              const SizedBox(height: 20),
              const Text(
                'Pengiriman pendaftaran belum tersedia. Data ini belum dikirim dan hanya tersimpan selama form terbuka.',
                style: TextStyle(color: AppTheme.muted, height: 1.5),
              ),
              const SizedBox(height: 16),
              const BasyaActionButton(
                label: 'Kirim pendaftaran',
                expand: true,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
