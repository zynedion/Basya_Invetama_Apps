import 'package:flutter/material.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/auth_exception.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.auth});
  final AuthService auth;
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _fields = List.generate(3, (_) => TextEditingController());
  final _hidden = [true, true, true];
  bool _busy = false, _uncertain = false;
  String? _error;
  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _uncertain || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    var saved = false;
    try {
      await widget.auth.changePassword(
        _fields[0].text,
        _fields[1].text,
        _fields[2].text,
      );
      saved = true;
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _uncertain = true;
          _error =
              'Hasil perubahan belum dapat dipastikan. Jangan kirim ulang. '
              'Jika perlu masuk kembali, coba kata sandi baru Anda.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!saved || !mounted) return;
    for (final field in _fields) {
      field.clear();
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kata sandi berhasil diperbarui.')),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Ganti kata sandi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Gunakan minimal 8 karakter dengan huruf besar, huruf kecil, dan angka.',
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextFormField(
                    controller: _fields[i],
                    obscureText: _hidden[i],
                    enabled: !_busy && !_uncertain,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: [
                        'Kata sandi saat ini',
                        'Kata sandi baru',
                        'Konfirmasi kata sandi baru',
                      ][i],
                      suffixIcon: IconButton(
                        tooltip: _hidden[i]
                            ? 'Tampilkan kata sandi'
                            : 'Sembunyikan kata sandi',
                        onPressed: () =>
                            setState(() => _hidden[i] = !_hidden[i]),
                        icon: Icon(
                          _hidden[i]
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final text = value ?? '';
                      if (text.isEmpty) return 'Wajib diisi.';
                      if (i == 1 &&
                          (text.length < 8 ||
                              !RegExp(r'[a-z]').hasMatch(text) ||
                              !RegExp(r'[A-Z]').hasMatch(text) ||
                              !RegExp(r'[0-9]').hasMatch(text))) {
                        return 'Minimal 8 karakter, huruf besar, huruf kecil, dan angka.';
                      }
                      if (i == 2 && text != _fields[1].text) {
                        return 'Konfirmasi kata sandi tidak sama.';
                      }
                      return null;
                    },
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              BasyaActionButton(
                expand: true,
                style: BasyaActionStyle.emphasis,
                loading: _busy,
                onPressed: _busy || _uncertain ? null : _submit,
                label: _busy ? 'Menyimpan...' : 'Simpan kata sandi',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
