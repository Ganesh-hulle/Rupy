import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/banks/bank_repository.dart';
import 'package:morpheus/banks/bank_search_cubit.dart';
import 'package:morpheus/creditcard_management_page.dart';

/// Dialog that lets users author a credit card and persists the selection
/// via the parent page. Bank field is type-ahead (top 5 only) to keep the
/// SQLite-backed list fast.
class AddCardDialog extends StatefulWidget {
  const AddCardDialog({super.key, this.existing});

  final CreditCard? existing;

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  final _formKey = GlobalKey<FormState>();

  final _bankCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _numCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  late final BankSearchCubit _bankSearchCubit;
  String? _bankIconUrl;

  Color _cardColor = const Color(0xFF1E3A8A);
  Color? _explicitTextColor;
  Color get _textColor =>
      _explicitTextColor ??
      (ThemeData.estimateBrightnessForColor(_cardColor) == Brightness.dark
          ? Colors.white
          : const Color(0xFF1F2937));

  @override
  void initState() {
    super.initState();
    _bankSearchCubit = BankSearchCubit(BankRepository())..preload();
    if (widget.existing != null) {
      _bankCtrl.text = widget.existing!.bankName;
      _holderCtrl.text = widget.existing!.holderName;
      _numCtrl.text = _groupCard(
        widget.existing!.cardNumber.replaceAll(RegExp(r'\\D'), ''),
      );
      _expCtrl.text = widget.existing!.expiryDate;
      _cvvCtrl.text = widget.existing!.cvv;
      _cardColor = widget.existing!.cardColor;
      _explicitTextColor = widget.existing!.textColor;
      _bankIconUrl = widget.existing!.bankIconUrl;
    } else {
      _prefillIcon(); // try to prefill icon if bank name matches top banks
    }
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _holderCtrl.dispose();
    _numCtrl.dispose();
    _expCtrl.dispose();
    _cvvCtrl.dispose();
    _bankSearchCubit.close();
    super.dispose();
  }

  Future<void> _prefillIcon() async {
    if (_bankCtrl.text.isEmpty) return;
    final repo = BankRepository();
    final icon = await repo.findIconByName(_bankCtrl.text.trim());
    if (mounted && icon != null) {
      setState(() => _bankIconUrl = icon);
    }
  }

  String _groupCard(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(d[i]);
    }
    return buffer.toString();
  }

  InputDecoration _cardDecoration(String label) {
    final faded = _textColor.withOpacity(0.75);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: faded, fontSize: 12),
      isDense: true,
      border: const UnderlineInputBorder(borderSide: BorderSide.none),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: faded.withOpacity(0.35)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: _textColor),
      ),
      contentPadding: EdgeInsets.zero,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }

  bool _validateAndSave() {
    if (!_formKey.currentState!.validate()) return false;
    final rawDigits = _numCtrl.text.replaceAll(RegExp(r'\D'), '');
    final grouped = _groupCard(rawDigits);

    final card = CreditCard(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      bankName: _bankCtrl.text.trim(),
      bankIconUrl: _bankIconUrl,
      cardNumber: grouped, // stored raw (encrypted remotely), masked in UI
      holderName: _holderCtrl.text.trim().toUpperCase(),
      expiryDate: _expCtrl.text.trim(),
      cvv: _cvvCtrl.text.trim(),
      cardColor: _cardColor,
      textColor: _explicitTextColor ?? _textColor,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(card);
    return true;
  }

  void _onBankSelected(String name) {
    _bankCtrl.text = name;
    _bankCtrl.selection = TextSelection.collapsed(offset: name.length);
    _prefillIcon();
  }

  // simple preset palette; we can extend or swap with a full picker later
  static const _palette = <Color>[
    Color(0xFF1E3A8A),
    Color(0xFF0EA5E9),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFFEA580C),
    Color(0xFF0F172A),
    Color(0xFF334155),
    Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.existing == null ? 'Add Card' : 'Edit Card',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1.586,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_cardColor, _cardColor.withOpacity(0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _cardColor.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -40,
                          top: -40,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -70,
                          bottom: -30,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildBankSearchField()),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.credit_card,
                                    color: _textColor.withOpacity(0.85),
                                    size: 28,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              TextFormField(
                                controller: _numCtrl,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 18,
                                  letterSpacing: 2,
                                ),
                                cursorColor: _textColor,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(19),
                                  TextInputFormatter.withFunction((oldV, newV) {
                                    final grouped = _groupCard(newV.text);
                                    return TextEditingValue(
                                      text: grouped,
                                      selection: TextSelection.collapsed(
                                        offset: grouped.length,
                                      ),
                                    );
                                  }),
                                ],
                                decoration: _cardDecoration('CARD NUMBER'),
                                validator: (v) {
                                  final d =
                                      v?.replaceAll(RegExp(r'\D'), '') ?? '';
                                  if (d.length < 12)
                                    return 'Enter a valid number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: TextFormField(
                                      controller: _holderCtrl,
                                      style: TextStyle(
                                        color: _textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      cursorColor: _textColor,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      decoration: _cardDecoration(
                                        'CARD HOLDER',
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                          ? 'Enter name'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _expCtrl,
                                      style: TextStyle(color: _textColor),
                                      cursorColor: _textColor,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        TextInputFormatter.withFunction((
                                          oldV,
                                          newV,
                                        ) {
                                          final t = newV.text;
                                          String out = t;
                                          if (t.length >= 3) {
                                            out =
                                                '${t.substring(0, 2)}/${t.substring(2)}';
                                          } else if (t.length >= 1 &&
                                              t.length <= 2) {
                                            out = t;
                                          }
                                          return TextEditingValue(
                                            text: out,
                                            selection: TextSelection.collapsed(
                                              offset: out.length,
                                            ),
                                          );
                                        }),
                                      ],
                                      decoration: _cardDecoration(
                                        'EXPIRES (MM/YY)',
                                      ),
                                      validator: (v) {
                                        final s = v?.trim() ?? '';
                                        final ok = RegExp(
                                          r'^(0[1-9]|1[0-2])/\d{2}$',
                                        ).hasMatch(s);
                                        return ok ? null : 'Invalid';
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _cvvCtrl,
                                      style: TextStyle(color: _textColor),
                                      cursorColor: _textColor,
                                      obscureText: true,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      decoration: _cardDecoration('CVV'),
                                      validator: (v) {
                                        final l = (v ?? '').length;
                                        return (l == 3 || l == 4)
                                            ? null
                                            : '3-4';
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildBankSuggestions(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ..._palette.map((c) {
                        final selected = c.value == _cardColor.value;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _cardColor = c;
                            _explicitTextColor = null;
                          }),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.black.withOpacity(0.35)
                                    : Colors.white,
                                width: selected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.palette_outlined, size: 18),
                        label: const Text('Custom'),
                        onPressed: _pickCustomColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _validateAndSave,
                      icon: const Icon(Icons.save),
                      label: Text(widget.existing == null ? 'Save' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankSearchField() {
    return BlocBuilder<BankSearchCubit, BankSearchState>(
      bloc: _bankSearchCubit,
      builder: (context, state) {
        return TextFormField(
          controller: _bankCtrl,
          style: TextStyle(color: _textColor, fontWeight: FontWeight.w600),
          cursorColor: _textColor,
          textCapitalization: TextCapitalization.words,
          decoration: _cardDecoration('BANK').copyWith(
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: state.loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _textColor,
                      ),
                    )
                  : Icon(
                      Icons.search_rounded,
                      color: _textColor.withOpacity(0.85),
                      size: 18,
                    ),
            ),
          ),
          onChanged: (v) => _bankSearchCubit.search(v),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Enter bank' : null,
        );
      },
    );
  }

  Widget _buildBankSuggestions() {
    return BlocBuilder<BankSearchCubit, BankSearchState>(
      bloc: _bankSearchCubit,
      builder: (context, state) {
        if (state.suggestions.isEmpty && state.loading) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading banks...'),
              ],
            ),
          );
        }

        if (state.suggestions.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Suggestions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (state.loading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.suggestions
                  .map(
                    (name) => ActionChip(
                      label: Text(name),
                      onPressed: () => _onBankSelected(name),
                      avatar: const Icon(Icons.account_balance, size: 16),
                    ),
                  )
                  .toList(),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 6),
              Text(
                state.error!,
                style: TextStyle(color: Colors.red.shade400, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pickCustomColor() async {
    double hue = HSVColor.fromColor(_cardColor).hue;
    double saturation = HSVColor.fromColor(_cardColor).saturation;
    double value = HSVColor.fromColor(_cardColor).value;

    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Pick a color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                label: 'Hue',
                min: 0,
                max: 360,
                divisions: 36,
                value: hue,
                onChanged: (v) => setLocal(() => hue = v),
              ),
              Slider(
                label: 'Saturation',
                min: 0,
                max: 1,
                divisions: 10,
                value: saturation,
                onChanged: (v) => setLocal(() => saturation = v),
              ),
              Slider(
                label: 'Brightness',
                min: 0.3,
                max: 1,
                divisions: 10,
                value: value.clamp(0.3, 1),
                onChanged: (v) => setLocal(() => value = v),
              ),
              const SizedBox(height: 12),
              Container(
                height: 40,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: HSVColor.fromAHSV(1, hue, saturation, value).toColor(),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                HSVColor.fromAHSV(1, hue, saturation, value).toColor(),
              ),
              child: const Text('Use color'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _cardColor = result;
        _explicitTextColor = null;
      });
    }
  }
}
