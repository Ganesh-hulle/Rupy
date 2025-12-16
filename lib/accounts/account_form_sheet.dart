import 'package:flutter/material.dart';
import 'package:morpheus/accounts/models/account_credential.dart';

class AccountFormSheet extends StatefulWidget {
  const AccountFormSheet({super.key, this.existing});

  final AccountCredential? existing;

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _websiteCtrl;
  Color? _brandColor;

  static const _palette = <Color>[
    Color(0xFF0EA5E9),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF334155),
  ];

  @override
  void initState() {
    super.initState();
    _bankCtrl = TextEditingController(text: widget.existing?.bankName ?? '');
    _usernameCtrl = TextEditingController(
      text: widget.existing?.username ?? '',
    );
    _passwordCtrl = TextEditingController(
      text: widget.existing?.password ?? '',
    );
    _websiteCtrl = TextEditingController(text: widget.existing?.website ?? '');
    _brandColor = widget.existing?.brandColor ?? _palette.first;
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _websiteCtrl.dispose();
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
            children: [
              Row(
                children: [
                  Text(
                    widget.existing == null ? 'Add account' : 'Edit account',
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
                controller: _bankCtrl,
                decoration: const InputDecoration(labelText: 'Bank name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Login / username',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Website (optional)',
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _palette
                      .map(
                        (c) => GestureDetector(
                          onTap: () => setState(() => _brandColor = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _brandColor == c
                                    ? Colors.black.withOpacity(0.4)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: _brandColor == c
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final account = AccountCredential(
      id: widget.existing?.id,
      bankName: _bankCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      lastUpdated: DateTime.now(),
      brandColor: _brandColor,
    );
    Navigator.of(context).pop(account);
  }
}
