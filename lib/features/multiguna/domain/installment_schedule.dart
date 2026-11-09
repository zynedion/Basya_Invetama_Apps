import 'loan_detail.dart';
import 'multiguna_overview_data.dart';

/// A calendar projection, not a payment ledger. Only offset zero is API-backed.
class InstallmentOccurrence {
  const InstallmentOccurrence(
    this.loan,
    this.date,
    this.number,
    this.estimated, {
    this.item,
  });
  final LoanInstallment? item;
  bool get paid => item?.paid ?? false;
  String get label =>
      item?.label ?? (estimated ? 'Perkiraan jadwal' : loan.paymentStatusLabel);
  int get amount => paid ? item!.amount : loan.installmentAmount;
  final MultigunaLoan loan;
  final DateTime date;
  final int number;
  final bool estimated;
  bool get overdue => item?.overdue ?? (!estimated && loan.isOverdue);
}

List<InstallmentOccurrence> installmentsOn(
  List<MultigunaLoan> loans,
  DateTime date, {
  Map<int, LoanDetail> details = const {},
}) {
  final day = DateTime(date.year, date.month, date.day);
  final result = <InstallmentOccurrence>[];
  for (final loan in loans) {
    final detail = details[loan.id];
    if (detail != null) {
      for (final item in detail.installments) {
        if (item.dueDate.year == day.year &&
            item.dueDate.month == day.month &&
            item.dueDate.day == day.day) {
          result.add(
            InstallmentOccurrence(loan, day, item.number, false, item: item),
          );
        }
      }
      continue;
    }
    final anchor = loan.nextDueDate;
    final offset = (day.year - anchor.year) * 12 + day.month - anchor.month;
    if (offset < 0 || loan.remainingBalance <= 0) continue;
    final number = loan.nextInstallmentNumber + offset;
    if (offset == 0) {
      if (day.day == anchor.day) {
        result.add(InstallmentOccurrence(loan, day, number, false));
      }
      continue;
    }
    // Stop at the earlier boundary if the API's end date and count disagree.
    if (loan.dueDay < 1 ||
        loan.dueDay > 31 ||
        loan.totalInstallments <= 0 ||
        number > loan.totalInstallments) {
      continue;
    }
    final lastDay = DateTime(day.year, day.month + 1, 0).day;
    final due = DateTime(day.year, day.month, loan.dueDay.clamp(1, lastDay));
    final end = DateTime(
      loan.endDate.year,
      loan.endDate.month,
      loan.endDate.day,
    );
    if (day == due && !day.isAfter(end) && !day.isBefore(loan.startDate)) {
      result.add(InstallmentOccurrence(loan, day, number, true));
    }
  }
  return result;
}
