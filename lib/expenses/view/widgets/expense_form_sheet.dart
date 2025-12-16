import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/expenses/constants/expense_categories.dart';
import 'package:morpheus/expenses/models/expense.dart';

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
  late final TextEditingController _noteCtrl;
  late String _currency;
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _amountCtrl = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.amount.toStringAsFixed(2)
          : '',
    );
    _noteCtrl = TextEditingController(text: widget.existing?.note ?? '');
    _currency = widget.existing?.currency ?? 'EUR';
    _category = widget.existing?.category ?? expenseCategories.first;
    _date = widget.existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
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
                decoration: const InputDecoration(
                  labelText: 'Item / description',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountCtrl,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final parsed = double.tryParse(v ?? '');
                        if (parsed == null || parsed <= 0)
                          return 'Enter amount';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      items: const ['EUR', 'INR', 'USD', 'GBP']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _currency = v ?? 'EUR'),
                      decoration: const InputDecoration(labelText: 'Currency'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _category,
                items: expenseCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? expenseCategories.first),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
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

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final note = _noteCtrl.text.trim();
    final expense = Expense(
      id: widget.existing?.id,
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      currency: _currency,
      category: _category,
      date: _date,
      note: note.isEmpty ? null : note,
      amountEur: widget.existing?.amountEur,
      budgetCurrency: widget.existing?.budgetCurrency,
      budgetRate: widget.existing?.budgetRate,
      amountInBudgetCurrency: widget.existing?.amountInBudgetCurrency,
    );
    Navigator.of(context).pop(expense);
  }
}
