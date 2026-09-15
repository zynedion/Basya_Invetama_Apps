import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/frosted_brand_background.dart';
import '../data/auth_exception.dart';
import '../data/auth_service.dart';
import '../domain/auth_gateway.dart';
import '../../home/presentation/investor_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.auth});

  final AuthGateway? auth;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _memberId = TextEditingController();
  final _password = TextEditingController();
  late final AuthGateway _auth = widget.auth ?? AuthService();
  bool _obscure = true;
  bool _submitting = false;
  String? _loginError;
  @override
  void dispose() {
    _memberId.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _loginError = null;
    });
    try {
      final session = await _auth.login(
        username: _memberId.text,
        password: _password.text,
      );
      final profile = await _auth.getProfile(session);
      if (!mounted) return;
      _password.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => InvestorHomePage(
            auth: _auth,
            profile: profile,
            audience: profile.usesInvestorHome
                ? HomeAudience.investor
                : HomeAudience.member,
          ),
        ),
        (_) => false,
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => _loginError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loginError = 'Login belum dapat diproses. Silakan coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.loginCanvas,
    body: Stack(
      children: [
        const Positioned.fill(child: FrostedBrandBackground()),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minHeight: (constraints.maxHeight - 56).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat datang',
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'di',
                              style: TextStyle(
                                fontSize: 30,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Image.asset(
                              'assets/logo/logo_basya.png',
                              width: 142,
                              height: 28,
                              fit: BoxFit.contain,
                              semanticLabel: 'Basya',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Simpanan dan investasi Anda,\ndalam satu genggaman.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _FieldLabel('Username atau email'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _memberId,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  hintText: 'Masukkan username atau email',
                                  errorStyle: TextStyle(fontSize: 0, height: 0),
                                  suffixIcon: Icon(
                                    Icons.person_outline,
                                    color: AppTheme.teal,
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? ''
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              const _FieldLabel('Kata sandi'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                enableSuggestions: false,
                                autocorrect: false,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!_submitting) _submit();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Masukkan kata sandi',
                                  errorStyle: const TextStyle(
                                    fontSize: 0,
                                    height: 0,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure
                                        ? 'Tampilkan kata sandi'
                                        : 'Sembunyikan kata sandi',
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.teal,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty ? '' : null,
                              ),
                              const SizedBox(height: 18),
                              if (_loginError != null) ...[
                                Semantics(
                                  liveRegion: true,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1F0),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFF4B8B3),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          size: 20,
                                          color: Color(0xFFB42318),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _loginError!,
                                            style: const TextStyle(
                                              color: Color(0xFF8A1C13),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF008579),
                                      AppTheme.teal,
                                      Color(0xFF004E50),
                                    ],
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: _submitting ? null : _submit,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: _submitting
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Masuk'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => _showInfo(
                            'Bantuan koperasi',
                            'Silakan hubungi pengurus koperasi untuk bantuan akun Anda.',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.muted,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 44),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.headset_mic_outlined, size: 18),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Butuh bantuan? Hubungi koperasi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Tumbuh bersama, melangkah lebih jauh.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.mint,
                            borderRadius: BorderRadius.circular(2),
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
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w600,
    ),
  );
}
