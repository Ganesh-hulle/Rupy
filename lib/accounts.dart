import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/accounts/account_form_sheet.dart';
import 'package:morpheus/accounts/accounts_cubit.dart';
import 'package:morpheus/accounts/accounts_repository.dart';
import 'package:morpheus/accounts/models/account_credential.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _listController;
  late final AccountsCubit _cubit;

  /// Track per-row visibility state.
  final Map<String, bool> _visible = {};

  @override
  void initState() {
    super.initState();
    _cubit = AccountsCubit(AccountsRepository())..load();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabController.forward();
    _listController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _listController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<AccountsCubit, AccountsState>(
        listenWhen: (prev, curr) =>
            prev.error != curr.error && curr.error != null,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          final items = state.items;
          return Scaffold(
            backgroundColor: colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 3,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surfaceTint,
              title: const Text(
                'My Accounts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              actions: [
                IconButton(
                  onPressed: () => _showSearchDialog(),
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search accounts',
                ),
                const SizedBox(width: 8),
              ],
            ),
            floatingActionButton: ScaleTransition(
              scale: _fabController,
              child: FloatingActionButton.extended(
                onPressed: _onAddAccountPressed,
                label: const Text('Add Account'),
                icon: const Icon(Icons.add_rounded),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                elevation: 6,
              ),
            ),
            body: state.loading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? _buildEmptyState()
                : AnimatedBuilder(
                    animation: _listController,
                    builder: (context, child) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) {
                          final animation = Tween<double>(begin: 0, end: 1)
                              .animate(
                                CurvedAnimation(
                                  parent: _listController,
                                  curve: Interval(
                                    (i * 0.1).clamp(0.0, 1.0),
                                    ((i * 0.1) + 0.3).clamp(0.0, 1.0),
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                              );

                          return SlideTransition(
                            position: animation.drive(
                              Tween<Offset>(
                                begin: const Offset(0.3, 0),
                                end: Offset.zero,
                              ),
                            ),
                            child: FadeTransition(
                              opacity: animation,
                              child: _buildAccountCard(items[i]),
                            ),
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No accounts yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first bank account to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AccountCredential acct) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isVisible = _visible[acct.id] ?? false;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              acct.brandColor?.withOpacity(0.05) ??
                  colorScheme.primary.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _BankAvatar(
                    name: acct.bankName,
                    color: acct.brandColor ?? colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acct.bankName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Updated ${_ago(acct.lastUpdated)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More options',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    itemBuilder: (_) => [
                      _buildPopupMenuItem(
                        Icons.copy_rounded,
                        'Copy username',
                        'copy_user',
                      ),
                      _buildPopupMenuItem(
                        Icons.key_rounded,
                        'Copy password',
                        'copy_pass',
                      ),
                      _buildPopupMenuItem(Icons.edit_rounded, 'Edit', 'edit'),
                      _buildPopupMenuItem(
                        Icons.delete_outline_rounded,
                        'Delete',
                        'delete',
                      ),
                    ],
                    onSelected: (value) => _onMenu(value, acct),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Credentials section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildCredentialRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Username',
                      value: acct.username,
                      copyValue: acct.username,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _buildCredentialRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Password',
                      value: isVisible ? acct.password : _mask(acct.password),
                      copyValue: acct.password,
                      theme: theme,
                      isPassword: true,
                      isVisible: isVisible,
                      onVisibilityToggle: () =>
                          setState(() => _visible[acct.id] = !isVisible),
                    ),
                  ],
                ),
              ),

              if (acct.website != null) ...[
                const SizedBox(height: 16),
                _buildWebsiteChip(acct.website!, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    IconData icon,
    String title,
    String value,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildCredentialRow({
    required IconData icon,
    required String label,
    required String value,
    required String copyValue,
    required ThemeData theme,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
  }) {
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFamily: isPassword ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPassword) ...[
              IconButton(
                onPressed: onVisibilityToggle,
                icon: Icon(
                  isVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                ),
                tooltip: isVisible ? 'Hide password' : 'Show password',
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
            ],
            IconButton(
              onPressed: () => _copy(copyValue, '$label copied'),
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy $label',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebsiteChip(String url, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              url,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ——— helpers ———

  static String _mask(String s) =>
      '•' * (s.isEmpty ? 8 : s.length.clamp(6, 12));

  static String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} mo ago';
    if (diff.inDays >= 1) return '${diff.inDays} d ago';
    if (diff.inHours >= 1) return '${diff.inHours} h ago';
    return '${diff.inMinutes} min ago';
  }

  void _onMenu(String action, AccountCredential acct) async {
    switch (action) {
      case 'copy_user':
        await _copy(acct.username, 'Username copied');
        break;
      case 'copy_pass':
        await _copy(acct.password, 'Password copied');
        break;
      case 'edit':
        _editAccount(acct);
        break;
      case 'delete':
        _deleteAccount(acct);
        break;
    }
  }

  Future<void> _copy(String text, String msg) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text(msg),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _editAccount(AccountCredential acct) {
    showModalBottomSheet<AccountCredential>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AccountFormSheet(existing: acct),
    ).then((value) {
      if (value != null) _cubit.save(value);
    });
  }

  void _deleteAccount(AccountCredential acct) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Text(
            'Are you sure you want to delete ${acct.bankName} account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cubit.delete(acct.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _onAddAccountPressed() {
    showModalBottomSheet<AccountCredential>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AccountFormSheet(),
    ).then((value) {
      if (value != null) _cubit.save(value);
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Accounts'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Search by bank name...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

/// Enhanced circle avatar with bank initials and brand colors.
class _BankAvatar extends StatelessWidget {
  final String name;
  final Color color;

  const _BankAvatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
