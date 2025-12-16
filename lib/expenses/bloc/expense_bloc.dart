import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/models/planned_expense.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/services/forex_service.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc(this._repository, {ForexService? forexService})
    : _forex = forexService ?? ForexService(),
      super(ExpenseState.initial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpense>(_onAddExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<SaveBudget>(_onSaveBudget);
    on<AddPlannedExpense>(_onAddPlannedExpense);
    on<ChangeMonth>(_onChangeMonth);
  }

  final ExpenseRepository _repository;
  final ForexService _forex;

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final expenses = await _repository.fetchExpenses();
      final budgets = await _repository.fetchBudgets();
      final nextState = _recompute(expenses, budgets, state.focusMonth);
      emit(nextState);
      await _refreshRates(nextState, emit);
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final prepared = await _withRates(event.expense);
      await _repository.addExpense(prepared);
      final updatedExpenses = [prepared, ...state.expenses];
      final nextState = _recompute(
        updatedExpenses,
        state.budgets,
        state.focusMonth,
      );
      emit(nextState);
      await _refreshRates(nextState, emit);
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final prepared = await _withRates(event.expense);
      await _repository.updateExpense(prepared);
      final updated = state.expenses
          .map((e) => e.id == prepared.id ? prepared : e)
          .toList();
      final nextState = _recompute(updated, state.budgets, state.focusMonth);
      emit(nextState);
      await _refreshRates(nextState, emit);
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.deleteExpense(event.expenseId);
      final updated = state.expenses
          .where((e) => e.id != event.expenseId)
          .toList();
      emit(_recompute(updated, state.budgets, state.focusMonth));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onSaveBudget(
    SaveBudget event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.saveBudget(event.budget);
      final updatedBudgets = [
        event.budget,
        ...state.budgets.where((b) => b.id != event.budget.id),
      ];
      final nextState = _recompute(
        state.expenses,
        updatedBudgets,
        state.focusMonth,
      );
      emit(nextState);
      await _refreshRates(nextState, emit);
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onAddPlannedExpense(
    AddPlannedExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addPlannedExpense(event.budgetId, event.expense);
      final updatedBudgets = state.budgets.map((b) {
        if (b.id == event.budgetId) {
          final planned = [...b.plannedExpenses, event.expense];
          return b.copyWith(plannedExpenses: planned);
        }
        return b;
      }).toList();
      emit(_recompute(state.expenses, updatedBudgets, state.focusMonth));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onChangeMonth(
    ChangeMonth event,
    Emitter<ExpenseState> emit,
  ) async {
    final nextState = _recompute(state.expenses, state.budgets, event.month);
    emit(nextState);
    await _refreshRates(nextState, emit);
  }

  ExpenseState _recompute(
    List<Expense> expenses,
    List<Budget> budgets,
    DateTime focusMonth,
  ) {
    final monthStart = DateTime(focusMonth.year, focusMonth.month, 1);
    final monthEnd = DateTime(
      focusMonth.year,
      focusMonth.month + 1,
      0,
      23,
      59,
      59,
      999,
    );

    final activeBudget = _budgetForMonth(budgets, focusMonth);
    final displayCurrency =
        activeBudget?.currency ??
        (expenses.isNotEmpty ? expenses.first.currency : 'EUR');
    final budgetToEur = activeBudget?.currency == 'EUR'
        ? 1.0
        : state.budgetToEur;

    final monthly = expenses
        .where((e) => !e.date.isBefore(monthStart) && !e.date.isAfter(monthEnd))
        .toList();
    final monthTotal = monthly.fold<double>(
      0,
      (sum, e) =>
          sum + _amountInDisplayCurrency(e, displayCurrency, budgetToEur),
    );
    final monthTotalEur = monthly.fold<double>(
      0,
      (sum, e) =>
          sum + (e.amountEur ?? (e.currency == 'EUR' ? e.amount : e.amount)),
    );

    final annualExpenses = expenses
        .where((e) => e.date.year == focusMonth.year)
        .toList();
    final annualTotal = annualExpenses.fold<double>(
      0,
      (sum, e) =>
          sum + _amountInDisplayCurrency(e, displayCurrency, budgetToEur),
    );
    final annualTotalEur = annualExpenses.fold<double>(
      0,
      (sum, e) =>
          sum + (e.amountEur ?? (e.currency == 'EUR' ? e.amount : e.amount)),
    );

    final Map<String, double> categoryTotals = {};
    for (final e in monthly) {
      final amount = _amountInDisplayCurrency(e, displayCurrency, budgetToEur);
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + amount;
    }

    final reservedPlanned = activeBudget?.reservedAmount ?? 0.0;
    final usableBudget = activeBudget != null
        ? (activeBudget.amount - reservedPlanned - monthTotal)
        : 0.0;

    return state.copyWith(
      loading: false,
      error: null,
      expenses: expenses,
      budgets: budgets,
      activeBudget: activeBudget,
      focusMonth: focusMonth,
      monthlyTotal: monthTotal,
      monthlyTotalEur: monthTotalEur,
      annualTotal: annualTotal,
      annualTotalEur: annualTotalEur,
      categoryTotals: categoryTotals,
      reservedPlanned: reservedPlanned,
      usableBudget: usableBudget,
      displayCurrency: displayCurrency,
    );
  }

  Future<Expense> _withRates(Expense expense, {List<Budget>? budgets}) async {
    final allBudgets = budgets ?? state.budgets;
    final budget = _budgetForDate(allBudgets, expense.date);
    final budgetCurrency = budget?.currency;

    double? rateToBudget;
    double? rateToEur;

    final symbols = <String>{'EUR'};
    if (budgetCurrency != null && budgetCurrency != expense.currency) {
      symbols.add(budgetCurrency);
    }

    try {
      if (symbols.isNotEmpty) {
        final rates = await _forex.fetchRates(
          date: expense.date,
          base: expense.currency,
          symbols: symbols.toList(),
        );
        rateToEur = rates['EUR'];
        if (budgetCurrency != null) {
          rateToBudget = rates[budgetCurrency];
        }
      }
    } catch (_) {
      // keep fallbacks below
    }

    final amountEur = expense.currency == 'EUR'
        ? expense.amount
        : rateToEur != null
        ? expense.amount * rateToEur
        : expense.amount;

    double? amountInBudgetCurrency;
    if (budgetCurrency != null) {
      if (budgetCurrency == expense.currency) {
        rateToBudget = 1;
        amountInBudgetCurrency = expense.amount;
      } else if (rateToBudget != null) {
        amountInBudgetCurrency = expense.amount * rateToBudget;
      } else if (budgetCurrency == 'EUR' && amountEur != null) {
        amountInBudgetCurrency = amountEur;
      }
    }

    return expense.copyWith(
      budgetCurrency: budgetCurrency ?? expense.budgetCurrency,
      budgetRate: rateToBudget ?? expense.budgetRate,
      amountInBudgetCurrency:
          amountInBudgetCurrency ?? expense.amountInBudgetCurrency,
      amountEur: amountEur,
    );
  }

  Budget? _budgetForMonth(List<Budget> budgets, DateTime month) {
    for (final b in budgets) {
      if (b.coversMonth(month)) return b;
    }
    return budgets.isNotEmpty ? budgets.first : null;
  }

  Budget? _budgetForDate(List<Budget> budgets, DateTime date) {
    for (final b in budgets) {
      final starts = !date.isBefore(
        DateTime(b.startDate.year, b.startDate.month, b.startDate.day),
      );
      final ends = !date.isAfter(
        DateTime(b.endDate.year, b.endDate.month, b.endDate.day, 23, 59, 59),
      );
      if (starts && ends) return b;
    }
    return null;
  }

  double _amountInDisplayCurrency(
    Expense expense,
    String displayCurrency,
    double? budgetToEur,
  ) {
    final converted = expense.amountForCurrency(displayCurrency);
    if (displayCurrency == expense.currency) return converted;

    if (displayCurrency == 'EUR' && expense.amountEur != null) {
      return expense.amountEur!;
    }

    if (converted != expense.amount) return converted;

    if (displayCurrency == expense.budgetCurrency &&
        expense.amountInBudgetCurrency != null) {
      return expense.amountInBudgetCurrency!;
    }

    if (budgetToEur != null &&
        budgetToEur > 0 &&
        expense.amountEur != null &&
        displayCurrency != 'EUR') {
      return expense.amountEur! / budgetToEur;
    }

    return converted;
  }

  Future<void> _refreshRates(
    ExpenseState baseState,
    Emitter<ExpenseState> emit,
  ) async {
    double? eurToInr = baseState.eurToInr;
    double? budgetToEur = baseState.budgetToEur;

    try {
      eurToInr = await _forex.latestRate(base: 'EUR', symbol: 'INR');
    } catch (_) {
      // ignore, keep previous value
    }

    final activeBudget = baseState.activeBudget;
    if (activeBudget != null && activeBudget.currency != 'EUR') {
      try {
        budgetToEur = await _forex.latestRate(
          base: activeBudget.currency,
          symbol: 'EUR',
        );
      } catch (_) {
        // ignore
      }
    } else {
      budgetToEur = 1.0;
    }

    emit(baseState.copyWith(eurToInr: eurToInr, budgetToEur: budgetToEur));
  }
}
