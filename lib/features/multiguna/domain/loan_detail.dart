class LoanInstallment {
  LoanInstallment(Map raw)
    : id = (raw['id'] as num).toInt(),
      reference = raw['trx_id'] as String,
      number = (raw['installment_number'] as num).toInt(),
      dueDate = DateTime.parse(raw['due_date'] as String),
      paymentDate = DateTime.tryParse(raw['payment_date']?.toString() ?? ''),
      status = (raw['status'] as Map)['key'] as String,
      statusLabel = (raw['status'] as Map)['label'] as String,
      paymentState = raw['payment_state'] as String?,
      amount = (raw['amount'] as num).toInt(),
      principal = (raw['principal'] as num).toInt(),
      margin = (raw['margin'] as num).toInt(),
      adjustment = (raw['adjustment'] as num).toInt(),
      method = raw['payment_method'] as String?,
      receipt = raw['receipt_url'] as String?;
  final int id, number, amount, principal, margin, adjustment;
  final String reference, status, statusLabel;
  final String? paymentState, method, receipt;
  final DateTime dueDate;
  final DateTime? paymentDate;
  bool get paid => status == 'paid';
  bool get overdue => status == 'billing' && paymentState == 'overdue';
  String get label => paid
      ? 'Lunas'
      : overdue
      ? 'Menunggak'
      : status == 'billing' && paymentState == 'upcoming'
      ? 'Belum jatuh tempo'
      : status == 'billing'
      ? 'Belum dibayar'
      : statusLabel;
}

class LoanDetail {
  LoanDetail(Map data)
    : contract = Map<String, dynamic>.from(data['contract'] as Map),
      object = Map<String, dynamic>.from(data['object'] as Map),
      financing = Map<String, dynamic>.from(data['financing'] as Map),
      summary = Map<String, dynamic>.from(data['installments_summary'] as Map),
      installments = List.unmodifiable(
        (data['installments'] as List)
            .map((e) => LoanInstallment(e as Map))
            .toList()
          ..sort((a, b) => a.number.compareTo(b.number)),
      );
  final Map<String, dynamic> contract, object, financing, summary;
  final List<LoanInstallment> installments;
  int get id => (contract['id'] as num).toInt();
  String get reference => contract['trx_id'] as String;
  int amount(String key) => (financing[key] as num?)?.toInt() ?? 0;
}
