import 'package:rupy/config/app_config.dart';
import 'package:rupy/expenses/models/expense.dart';

double amountInDisplayCurrency(
  Expense expense,
  String displayCurrency,
  double? budgetToEur,
) {
  // Always return the raw amount, ignoring currency conversion
  // or assuming everything is already INR.
  return expense.amount;
}

String? alternateCurrency(String currency) {
  return null;
}

double? convertToAlternateCurrency({
  required double amount,
  required String currency,
  double? baseToSecondaryRate,
  double? currencyToBaseRate,
}) {
  return null;
}

double? expenseAmountInBaseCurrency(
  Expense expense,
  double? baseToSecondaryRate,
) {
  return expense.amount;
}

double? expenseAmountInSecondaryCurrency(
  Expense expense,
  double? baseToSecondaryRate,
) {
  return null;
}
