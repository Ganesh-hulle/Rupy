import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rupy/categories/category_cubit.dart';
import 'package:rupy/categories/expense_category.dart';
import 'package:rupy/utils/category_color.dart';

class CategorySettingsPage extends StatelessWidget {
  const CategorySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'restore') {
                _confirmRestoreDefaults(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'restore',
                child: Text('Restore defaults'),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.items.isEmpty) {
             return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No categories found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.read<CategoryCubit>().addDefaultCategories(),
                    child: const Text('Add defaults'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = state.items[index];
              return _CategoryTile(category: category);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _promptAddCategory(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Future<void> _confirmRestoreDefaults(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore defaults?'),
        content: const Text('This will add any missing default categories. Existing categories will not be changed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore'),
          ),
        ],
      )
    ) ?? false;

    if (confirm && context.mounted) {
      context.read<CategoryCubit>().addDefaultCategories();
    }
  }

  Future<void> _promptAddCategory(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Category name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emojiCtrl,
                decoration: const InputDecoration(labelText: 'Emoji (optional)', hintText: 'e.g. 🍔'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ) ?? false;

    if (shouldSave && context.mounted) {
      final name = nameCtrl.text.trim();
      final emoji = emojiCtrl.text.trim();
      await context.read<CategoryCubit>().addCategory(name: name, emoji: emoji.isEmpty ? '' : emoji);
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    // Show emoji or an icon if emoji is missing
    Widget leading;
    if (category.emoji.isNotEmpty) {
      leading = Text(category.emoji, style: const TextStyle(fontSize: 24));
    } else {
      leading = CircleAvatar(
        backgroundColor: getCategoryColor(category.name).withOpacity(0.2),
        child: Icon(Icons.label, color: getCategoryColor(category.name)),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: SizedBox(
        width: 40,
        height: 40,
        child: Center(child: leading),
      ),
      title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        tooltip: 'Delete',
        onPressed: () => _confirmDelete(context),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm && context.mounted) {
      context.read<CategoryCubit>().deleteCategory(category.id);
    }
  }
}
