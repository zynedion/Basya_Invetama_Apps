import 'multiguna_overview_data.dart';

/// A calendar projection, not a payment ledger. Only offset zero is API-backed.
class InstallmentOccurrence {
  const InstallmentOccurrence(
    this.loan,
    this.date,
    this.number,
    this.estimated,
  );
  final MultigunaLoan loan;
  final DateTime date;
  final int number;
  final bool estimated;
  bool get overdue => !estimated && loan.isOverdue;
}

List<InstallmentOccurrence> installmentsOn(
  List<MultigunaLoan> loans,
  DateTime date,
) {
  final day = DateTime(date.year, date.month, date.day);
  final result = <InstallmentOccurrence>[];
  for (final loan in loans) {
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
