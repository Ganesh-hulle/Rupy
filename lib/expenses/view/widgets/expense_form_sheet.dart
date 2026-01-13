import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rupy/expenses/models/expense.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rupy/categories/category_cubit.dart';
import 'package:rupy/categories/expense_category.dart';
import 'package:rupy/expenses/bloc/expense_bloc.dart';

class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({super.key, this.existing});

  final Expense? existing;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  final FocusNode _titleFocus = FocusNode();
  late String _category;
  late DateTime _date;
  late String _transactionType;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _amountCtrl = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.amount.toStringAsFixed(2)
          : '',
    );
    _category = widget.existing?.category ?? '';
    _date = widget.existing?.date ?? DateTime.now();
    _transactionType = widget.existing?.transactionType ?? 'spend';
    _amountCtrl.addListener(_onAmountChanged);
    _titleFocus.addListener(_onFocusChange);
    _calculateSuggestions();
  }

  void _calculateSuggestions() {
    final expenses = context.read<ExpenseBloc>().state.expenses;
    final frequency = <String, int>{};
    for (final e in expenses) {
      final title = e.title.trim();
      if (title.isNotEmpty) {
        frequency[title] = (frequency[title] ?? 0) + 1;
      }
    }
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    setState(() {
      _suggestions = sorted.take(3).map((e) => e.key).toList();
    });
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _titleFocus.removeListener(_onFocusChange);
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categoryState = context.watch<CategoryCubit>().state;
    final categories = categoryState.items;
    if (categories.isNotEmpty &&
        (_category.isEmpty || !categories.any((c) => c.name == _category))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _category = categories.first.name);
      });
    }
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.existing == null ? 'Add Expense' : 'Edit Expense',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                focusNode: _titleFocus,
                decoration: const InputDecoration(
                  labelText: 'Item / description',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              if (_titleFocus.hasFocus && _suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _suggestions.map((s) {
                    return ActionChip(
                      label: Text(s),
                      onPressed: () => _applySuggestion(s),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final parsed = double.tryParse(v ?? '');
                  if (parsed == null || parsed <= 0) return 'Enter amount';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              if (categories.isEmpty)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    helperText: 'Add default categories in Settings',
                  ),
                  child: Row(
                    children: [
                      if (categoryState.loading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.info_outline, size: 18),
                      const SizedBox(width: 8),
                      const Text('No categories available'),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _category.isEmpty ? categories.first.name : _category,
                  items: _categoryItems(categories, _category),
                  onChanged: (v) => setState(() => _category = v ?? _category),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Select category' : null,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              const SizedBox(height: 10),
              _buildTransactionType(),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(widget.existing == null ? 'Save' : 'Update'),
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applySuggestion(String title) {
    _titleCtrl.text = title;
    final expenses = context.read<ExpenseBloc>().state.expenses;
    // Find most recent category for this title
    try {
      final match = expenses.firstWhere(
        (e) => e.title.toLowerCase() == title.toLowerCase(),
      );
      setState(() {
        _category = match.category;
      });
    } catch (_) {}
  }

  Widget _buildTransactionType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transaction type'),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'spend', label: Text('Spend')),
            ButtonSegment(value: 'transfer', label: Text('Transfer')),
          ],
          selected: {_transactionType},
          onSelectionChanged: (selection) {
            setState(() => _transactionType = selection.first);
          },
        ),
      ],
    );
  }

  void _onAmountChanged() {
    if (!mounted) return;
    setState(() {});
  }

  List<DropdownMenuItem<String>> _categoryItems(
    List<ExpenseCategory> categories,
    String selected,
  ) {
    final items = categories
        .map(
          (c) => DropdownMenuItem(value: c.name, child: Text(c.label)),
        )
        .toList();
    if (selected.isNotEmpty && !categories.any((c) => c.name == selected)) {
      items.add(
        DropdownMenuItem(value: selected, child: Text(selected)),
      );
    }
    return items;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final categories = context.read<CategoryCubit>().state.items;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add categories in Settings first.')),
      );
      return;
    }
    
    // Defaults
    const defaultCurrency = 'INR';
    const defaultPaymentSourceType = 'cash';
    final defaultPaymentSourceId = null;

    final expense = Expense.create(
      id: widget.existing?.id,
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      currency: defaultCurrency,
      category: _category,
      date: _date,
      note: null, // Note removed
      amountEur: widget.existing?.amountEur,
      budgetCurrency: widget.existing?.budgetCurrency,
      budgetRate: widget.existing?.budgetRate,
      amountInBudgetCurrency: widget.existing?.amountInBudgetCurrency,
      paymentSourceType: defaultPaymentSourceType,
      paymentSourceId: defaultPaymentSourceId,
      transactionType: _transactionType.toLowerCase(),
    );
    Navigator.of(context).pop(expense);
  }
}
