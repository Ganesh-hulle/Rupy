import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:morpheus/auth/auth_bloc.dart';
import 'package:morpheus/expenses/bloc/expense_bloc.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/models/planned_expense.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/expenses/view/widgets/budget_sheet.dart';
import 'package:morpheus/expenses/view/widgets/expense_form_sheet.dart';
import 'package:morpheus/expenses/view/widgets/planned_expense_sheet.dart';

class ExpenseDashboardPage extends StatelessWidget {
  const ExpenseDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpenseBloc(ExpenseRepository())..add(const LoadExpenses()),
      child: const _ExpenseDashboardView(),
    );
  }
}

class _ExpenseDashboardView extends StatelessWidget {
  const _ExpenseDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses & Budget'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ExpenseBloc>().add(const LoadExpenses()),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthBloc>().add(const SignOutRequested());
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'logout', child: Text('Logout'))],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseForm(context),
        icon: const Icon(Icons.add_chart),
        label: const Text('Add expense'),
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listenWhen: (previous, current) => previous.error != current.error && current.error != null,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state.loading && state.expenses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<ExpenseBloc>().add(const LoadExpenses()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                _ForexBadge(rate: state.eurToInr),
                const SizedBox(height: 12),
                _MetricsRow(state: state),
                const SizedBox(height: 12),
                _UsableBudgetCard(state: state),
                const SizedBox(height: 12),
                _BurnChart(state: state),
                const SizedBox(height: 12),
                _CategoryChart(state: state),
                const SizedBox(height: 12),
                _BudgetCard(state: state),
                const SizedBox(height: 12),
                _ExpenseList(
                  state: state,
                  onEdit: (expense) => _openExpenseForm(context, existing: expense),
                  onDelete: (expense) => _confirmDeleteExpense(context, expense),
                  onExport: () => _exportExpenses(context, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openExpenseForm(BuildContext context, {Expense? existing}) async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExpenseFormSheet(existing: existing),
    );
    if (result != null) {
      // ignore: use_build_context_synchronously
      if (existing == null) {
        context.read<ExpenseBloc>().add(AddExpense(result));
      } else {
        context.read<ExpenseBloc>().add(UpdateExpense(result));
      }
    }
  }

  Future<void> _confirmDeleteExpense(BuildContext context, Expense expense) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete expense'),
            content: Text('Remove "${expense.title}" from your records?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (shouldDelete) {
      // ignore: use_build_context_synchronously
      context.read<ExpenseBloc>().add(DeleteExpense(expense.id));
    }
  }

  Future<void> _exportExpenses(BuildContext context, ExpenseState state) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDateRange: DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
    );

    if (range == null) return;

    // Permissions check before writing to downloads/documents.
    if (Platform.isAndroid) {
      final ok = await _ensureAndroidStoragePermission(context);
      if (!ok) return;
    }

    final filtered = state.expenses.where((e) {
      return !e.date.isBefore(range.start) && !e.date.isAfter(range.end);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final buffer = StringBuffer();
    buffer.writeln('Expenses export (${DateFormat.yMMMd().format(range.start)} - ${DateFormat.yMMMd().format(range.end)})');
    buffer.writeln('Title,Amount,Currency,Category,Date,Note');
    for (final e in filtered) {
      buffer.writeln(
        '"${e.title.replaceAll('"', "'")}",${e.amount.toStringAsFixed(2)},${e.currency},${e.category},${DateFormat('yyyy-MM-dd').format(e.date)},"${(e.note ?? '').replaceAll('"', "'")}"',
      );
    }

    final budget = state.activeBudget;
    if (budget != null) {
      buffer.writeln('');
      buffer.writeln('Budget summary');
      buffer.writeln('Amount (${budget.currency}),Start,End,Reserved,Usable');
      buffer.writeln(
        '${budget.amount.toStringAsFixed(2)},${DateFormat('yyyy-MM-dd').format(budget.startDate)},${DateFormat('yyyy-MM-dd').format(budget.endDate)},${state.reservedPlanned.toStringAsFixed(2)},${state.usableBudget.toStringAsFixed(2)}',
      );

      if (budget.plannedExpenses.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Future expenses');
        buffer.writeln('Title,Amount,Due,Category');
        for (final p in budget.plannedExpenses) {
          buffer.writeln(
            '"${p.title.replaceAll('"', "'")}",${p.amount.toStringAsFixed(2)},${DateFormat('yyyy-MM-dd').format(p.dueDate)},${p.category ?? '-'}',
          );
        }
      }
    }

    // Prefer Downloads on Android; Documents elsewhere.
    Directory baseDir;
    if (Platform.isAndroid) {
      // Force public Downloads so files are visible to user file managers.
      baseDir = Directory('/storage/emulated/0/Download');
      if (!await baseDir.exists()) {
        final candidates = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        baseDir =
            (candidates?.isNotEmpty == true ? candidates!.first : await getExternalStorageDirectory()) ??
            await getApplicationDocumentsDirectory();
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final exportDir = Directory('${baseDir.path}/morpheus_exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File('${exportDir.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported ${filtered.length} expenses to ${file.path}')));
  }

  Future<bool> _ensureAndroidStoragePermission(BuildContext context) async {
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) return true;

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    if (!context.mounted) return false;
    final permanentlyDenied = storageStatus.isPermanentlyDenied || manageStatus.isPermanentlyDenied;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Storage permission denied. Please allow to export.'),
        action: permanentlyDenied ? SnackBarAction(label: 'Settings', onPressed: openAppSettings) : null,
      ),
    );
    return false;
  }
}

class _ForexBadge extends StatelessWidget {
  const _ForexBadge({required this.rate});

  final double? rate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = rate == null ? 'Fetching EUR → INR...' : 'EUR → INR today: ₹${rate!.toStringAsFixed(2)}';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.currency_exchange, color: colorScheme.onPrimaryContainer, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsableBudgetCard extends StatelessWidget {
  const _UsableBudgetCard({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = state.activeBudget;
    final currency = budget?.currency ?? state.displayCurrency;
    final fmt = NumberFormat.simpleCurrency(name: currency);
    final usable = state.usableBudget;
    final range = budget == null
        ? 'No budget set'
        : '${DateFormat.MMMd().format(budget.startDate)} · ${DateFormat.MMMd().format(budget.endDate)}';
    final budgetToEur = state.budgetToEur ?? (currency == 'EUR' ? 1.0 : null);
    final usableEur = (budgetToEur != null && budgetToEur > 0) ? usable * budgetToEur : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.account_balance_wallet, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Usable budget', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(range, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Text(
                    budget == null ? '—' : fmt.format(usable),
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (budget != null && currency != 'EUR' && usableEur != null)
                    Text(
                      '≈ ${NumberFormat.simpleCurrency(name: 'EUR').format(usableEur)} today',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    final currency = state.displayCurrency;
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'This month',
            value: _money(state.monthlyTotal, currency),
            subtitle: 'Spent in ${DateFormat.MMM().format(state.focusMonth)}',
            icon: Icons.calendar_month,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'This year',
            value: _money(state.annualTotal, currency),
            subtitle: 'Year-to-date',
            icon: Icons.timeline,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  String _money(double amount, String currency) {
    final fmt = NumberFormat.simpleCurrency(name: currency);
    return fmt.format(amount);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: color.withOpacity(0.09),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BurnChart extends StatelessWidget {
  const _BurnChart({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    return _MonthlyLineChart(
      expenses: state.expenses,
      focusMonth: state.focusMonth,
      displayCurrency: state.displayCurrency,
      budgetToEur: state.budgetToEur,
    );
  }
}

class _MonthlyLineChart extends StatelessWidget {
  const _MonthlyLineChart({required this.expenses, required this.focusMonth, required this.displayCurrency, this.budgetToEur});

  final List<Expense> expenses;
  final DateTime focusMonth;
  final String displayCurrency;
  final double? budgetToEur;

  @override
  Widget build(BuildContext context) {
    final now = DateTime(focusMonth.year, focusMonth.month, 1);
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final values = <double>[];
    for (final m in months) {
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59);
      final total = expenses
          .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
          .fold<double>(0, (sum, e) => sum + _amount(e));
      values.add(total);
    }

    final maxY = ((values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0).clamp(0, double.infinity) as double) + 50;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('6-month burn', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= months.length) return const SizedBox.shrink();
                          return Text(DateFormat.MMM().format(months[index]), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
                      color: Colors.indigo,
                      isCurved: true,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.indigo.withOpacity(0.15)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _amount(Expense expense) {
    final converted = expense.amountForCurrency(displayCurrency);
    if (displayCurrency == expense.currency) return converted;
    if (displayCurrency == 'EUR' && expense.amountEur != null) return expense.amountEur!;
    if (converted != expense.amount) return converted;
    if (budgetToEur != null && budgetToEur! > 0 && expense.amountEur != null && displayCurrency != 'EUR') {
      return expense.amountEur! / budgetToEur!;
    }
    return converted;
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    return _CategoryPieChart(categoryTotals: state.categoryTotals);
  }
}

class _CategoryPieChart extends StatelessWidget {
  const _CategoryPieChart({required this.categoryTotals});

  final Map<String, double> categoryTotals;

  @override
  Widget build(BuildContext context) {
    final items = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = items.fold<double>(0, (sum, e) => sum + e.value);

    if (items.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Category mix', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Add expenses to see where your money goes.'),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category mix', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  sections: [
                    for (var i = 0; i < items.length; i++)
                      PieChartSectionData(
                        value: items[i].value,
                        title: '${((items[i].value / total) * 100).toStringAsFixed(0)}%',
                        color: Colors.primaries[i % Colors.primaries.length],
                        radius: 70,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < items.length; i++)
                  Chip(
                    avatar: CircleAvatar(backgroundColor: Colors.primaries[i % Colors.primaries.length]),
                    label: Text('${items[i].key} • ${items[i].value.toStringAsFixed(0)}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    final budget = state.activeBudget;
    final currency = budget?.currency ?? state.displayCurrency;
    final fmt = NumberFormat.simpleCurrency(name: currency);
    final spent = state.monthlyTotal;
    final budgetToEur = state.budgetToEur ?? (currency == 'EUR' ? 1.0 : null);
    final eurFmt = NumberFormat.simpleCurrency(name: 'EUR');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget planner', style: Theme.of(context).textTheme.titleMedium),
                FilledButton.icon(
                  onPressed: () => _openBudgetSheet(context, budget),
                  icon: const Icon(Icons.savings),
                  label: Text(budget == null ? 'Set budget' : 'Adjust'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (budget == null) ...[
              const Text('Set a monthly/period budget and we will track it for you.'),
            ] else ...[
              Text('${fmt.format(spent)} spent of ${fmt.format(budget.amount)}', style: Theme.of(context).textTheme.titleSmall),
              if (currency != 'EUR' && budgetToEur != null) ...[
                const SizedBox(height: 4),
                Text(
                  '≈ ${eurFmt.format(budget.amount * budgetToEur)} budget today',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 8),
              LinearProgressIndicator(
                minHeight: 8,
                borderRadius: BorderRadius.circular(5),
                value: (budget.amount == 0) ? 0 : (spent / budget.amount).clamp(0, 1),
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: const Icon(Icons.event, size: 16),
                    label: Text('${DateFormat.MMMd().format(budget.startDate)} - ${DateFormat.MMMd().format(budget.endDate)}'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.schedule, size: 16),
                    label: Text('Planned: ${fmt.format(state.reservedPlanned)}'),
                  ),
                  Chip(avatar: const Icon(Icons.balance, size: 16), label: Text('Usable: ${fmt.format(state.usableBudget)}')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Future expenses', style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: () => _openPlannedExpenseSheet(context, budget.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (budget.plannedExpenses.isEmpty)
                const Text('No future expenses yet')
              else
                Column(
                  children: budget.plannedExpenses
                      .map(
                        (p) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.push_pin),
                          title: Text(p.title),
                          subtitle: Text(DateFormat.MMMd().format(p.dueDate)),
                          trailing: Text(fmt.format(p.amount)),
                        ),
                      )
                      .toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openBudgetSheet(BuildContext context, Budget? existing) async {
    final result = await showModalBottomSheet<Budget>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BudgetSheet(existing: existing),
    );
    if (result != null) {
      // ignore: use_build_context_synchronously
      context.read<ExpenseBloc>().add(SaveBudget(result));
    }
  }

  Future<void> _openPlannedExpenseSheet(BuildContext context, String budgetId) async {
    final result = await showModalBottomSheet<PlannedExpense>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PlannedExpenseSheet(),
    );
    if (result != null) {
      // ignore: use_build_context_synchronously
      context.read<ExpenseBloc>().add(AddPlannedExpense(budgetId: budgetId, expense: result));
    }
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.state, required this.onEdit, required this.onDelete, required this.onExport});

  final ExpenseState state;
  final void Function(Expense expense) onEdit;
  final void Function(Expense expense) onDelete;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    if (state.expenses.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text('No expenses yet'),
              const SizedBox(height: 8),
              Text(
                'Add your first expense to start seeing charts and trends.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final fmt = NumberFormat.simpleCurrency(name: state.displayCurrency);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent expenses', style: TextStyle(fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    IconButton(tooltip: 'Export (CSV)', icon: const Icon(Icons.file_download_outlined), onPressed: onExport),
                    Text(DateFormat.yMMM().format(state.focusMonth)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...state.expenses
              .take(10)
              .map(
                (e) => ListTile(
                  onTap: () => onEdit(e),
                  leading: CircleAvatar(
                    backgroundColor: Colors.primaries[e.category.hashCode % Colors.primaries.length].withOpacity(0.15),
                    child: Icon(Icons.label, color: Colors.primaries[e.category.hashCode % Colors.primaries.length]),
                  ),
                  title: Text(e.title),
                  subtitle: Text('${e.category} • ${DateFormat.MMMd().format(e.date)}'),
                  trailing: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(fmt.format(e.amountForCurrency(state.displayCurrency))),
                      IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit, size: 18), onPressed: () => onEdit(e)),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => onDelete(e),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
