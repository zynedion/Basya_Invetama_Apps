import 'package:flutter/material.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/domain/auth_session.dart';
import '../../forms/presentation/form_widgets.dart';
import '../data/profile_edit_api.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, required this.session, this.api});
  final AuthSession session;
  final ProfileEditApi? api;
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final _api = widget.api ?? ProfileEditApi();
  final _form = GlobalKey<FormState>();
  static const labels = {
    'full_name': 'Nama',
    'email': 'Email',
    'contact': 'Nomor telepon',
    'address': 'Alamat',
    'account_name': 'Nama pemilik rekening',
    'norek': 'Nomor rekening',
  };
  final _fields = {for (final key in labels.keys) key: TextEditingController()};
  Map<String, dynamic>? _data;
  int? _bank;
  LocalAttachment? _photo;
  String? _error;
  bool _loading = true,
      _busy = false,
      _reviewing = false,
      _dirty = false,
      _saved = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.options(widget.session);
      if (!mounted) return;
      final p = data['profile'] as Map;
      final bank = p['bank_account'] as Map? ?? {};
      for (final key in labels.keys) {
        _fields[key]!.text =
            '${key == 'account_name'
                ? bank['account_name'] ?? ''
                : key == 'norek'
                ? bank['account_no'] ?? ''
                : p[key] ?? ''}';
      }
      setState(() {
        _data = data;
        _bank =
            (data['bank_options'] as List).any(
              (e) => e['id'] == bank['bank_id'],
            )
            ? bank['bank_id'] as int?
            : null;
        _dirty = false;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ProfileEditFailure
              ? e.message
              : 'Profil belum dapat dimuat.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _canLeave() async {
    if (_busy || _reviewing) return false;
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tinggalkan perubahan?'),
            content: const Text('Perubahan belum disimpan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Lanjutkan mengisi'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Tinggalkan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save() async {
    if (_busy || _reviewing || !_form.currentState!.validate()) return;
    _reviewing = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan perubahan profil?'),
        content: const Text(
          'Perubahan profil dan rekening bank langsung berlaku setelah disimpan. Pastikan data rekening sudah benar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Periksa kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
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
      await _api.save(widget.session, {
        for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
        'bank_id': '$_bank',
      }, _photo);
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _busy = false;
        _saved = true;
      });
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ProfileEditFailure
              ? e.message
              : 'Hasil penyimpanan belum dapat dipastikan. Periksa profil terbaru sebelum mencoba kembali.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _data?['profile']?['foto_user'] as String?;
    return PopScope(
      canPop: _saved || (!_dirty && !_busy && !_reviewing),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _canLeave() && mounted) {
          setState(() => _dirty = false);
          await WidgetsBinding.instance.endOfFrame;
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit profil')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) Text(_error!),
              if (_data == null && !_loading)
                TextButton(onPressed: _load, child: const Text('Coba lagi')),
              if (_data != null)
                Form(
                  key: _form,
                  child: AbsorbPointer(
                    absorbing: _busy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ClipOval(
                            child: _photo != null
                                ? Image.memory(
                                    _photo!.bytes,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : url != null && url.isNotEmpty
                                ? Image.network(
                                    url,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.person, size: 80),
                                  )
                                : const Icon(Icons.person, size: 80),
                          ),
                        ),
                        const SizedBox(height: 16),
                        BasyaAttachmentField(
                          label: 'Foto profil',
                          imageOnly: true,
                          required: false,
                          onChanged: (v) => setState(() {
                            _photo = v;
                            _dirty = true;
                          }),
                        ),
                        for (final entry in labels.entries) ...[
                          const SizedBox(height: 20),
                          if (entry.key == 'account_name') ...[
                            const FormSection('Informasi rekening bank'),
                            DropdownButtonFormField<int>(
                              initialValue: _bank,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Bank',
                              ),
                              items: [
                                for (final bank
                                    in _data!['bank_options'] as List)
                                  DropdownMenuItem(
                                    value: bank['id'] as int,
                                    child: Text(
                                      '${bank['name']}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(() {
                                _bank = v;
                                _dirty = true;
                              }),
                              validator: (v) =>
                                  v == null ? 'Pilih bank.' : null,
                            ),
                            const SizedBox(height: 20),
                          ],
                          TextFormField(
                            controller: _fields[entry.key],
                            maxLength: entry.key == 'address'
                                ? 2000
                                : entry.key == 'account_name'
                                ? 100
                                : entry.key == 'contact'
                                ? null
                                : 50,
                            maxLines: entry.key == 'address' ? 3 : 1,
                            keyboardType: entry.key == 'email'
                                ? TextInputType.emailAddress
                                : entry.key == 'contact'
                                ? TextInputType.phone
                                : entry.key == 'norek'
                                ? TextInputType.number
                                : TextInputType.text,
                            decoration: InputDecoration(labelText: entry.value),
                            onChanged: (_) => setState(() => _dirty = true),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) {
                                return '${entry.value} wajib diisi.';
                              }
                              if (entry.key == 'email' &&
                                  !RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(value)) {
                                return 'Masukkan email yang valid.';
                              }
                              if (entry.key == 'contact' &&
                                  !RegExp(
                                    r'^(08|628|\+628)\d{6,12}$',
                                  ).hasMatch(value)) {
                                return 'Gunakan format 08, 628, atau +628.';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        BasyaActionButton(
                          label: 'Simpan perubahan',
                          style: BasyaActionStyle.emphasis,
                          expand: true,
                          loading: _busy,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
