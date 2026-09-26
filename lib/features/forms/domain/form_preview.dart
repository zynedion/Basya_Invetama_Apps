import 'package:flutter/services.dart';

enum BasyaFormKind {
  topUpSavings(
    'Top Up Sukarela',
    'Tambah saldo yang dapat ditarik kapan saja.',
  ),
  topUpBuyPower('Top Up Buy Power', 'Tambah dana untuk pembelian investasi.'),
  mandatorySavings(
    'Bayar Simpanan Wajib',
    'Bayar iuran keanggotaan secara manual.',
  ),
  withdraw('Withdraw Sukarela', 'Dana dicairkan ke rekening terdaftar.'),
  mutation(
    'Mutasi ke Sukarela',
    'Pindahkan dana dari Buy Power ke Simpanan Sukarela.',
  ),
  installment('Bayar Cicilan', 'Catat pembayaran untuk kontrak Multiguna.'),
  financing('Ajukan Multiguna', 'Lengkapi data pembiayaan dan jaminan.'),
  editProfile('Edit Profil', 'Perbarui informasi yang dapat dihubungi.'),
  password(
    'Ganti Password',
    'Gunakan kata sandi yang berbeda dari akun lainnya.',
  );

  const BasyaFormKind(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

/// Fixtures for the frontend preview only; never a source of financial truth.
abstract final class FormPreview {
  static const savings = 12500000;
  static const buyPower = 5000000;
  static const mandatoryAmount = 100000;
  static const financingLimit = 7250000;
  static const banks = ['Bank Mandiri', 'BCA', 'BNI', 'BRI', 'BSI'];
  static const cooperativeAccounts = [
    'Mandiri · 1234 5678 9000 · Koperasi Basya (contoh)',
    'BSI · 7000 1234 5678 · Koperasi Basya (contoh)',
  ];
  static const months = [
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
}

String rupiah(int value) => 'Rp ${groupDigits(value.toString())}';

String groupDigits(String digits) => digits.replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]}.',
);

int moneyValue(String value) =>
    int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 12) return oldValue;
    if (digits.isEmpty) return const TextEditingValue();
    final before = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final digitsBefore = newValue.text
        .substring(0, before)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    final originalLength = digits.length;
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = groupDigits(digits);
    final target = (digitsBefore - (originalLength - digits.length)).clamp(
      0,
      digits.length,
    );
    var offset = 0;
    var count = 0;
    while (offset < formatted.length && count < target) {
      if (formatted[offset] != '.') count++;
      offset++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
