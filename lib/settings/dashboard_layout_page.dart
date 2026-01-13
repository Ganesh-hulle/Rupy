import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rupy/settings/models/dashboard_widget_type.dart';
import 'package:rupy/settings/settings_cubit.dart';
import 'package:rupy/settings/settings_state.dart';

class DashboardLayoutPage extends StatelessWidget {
  const DashboardLayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Layout'),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final layout = state.dashboardLayout;
          final hidden = state.hiddenWidgets;
          final theme = Theme.of(context);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Customize your dashboard by reordering or hiding items.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              SliverReorderableList(
                itemCount: layout.length,
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final newLayout = List<DashboardWidgetType>.from(layout);
                  final item = newLayout.removeAt(oldIndex);
                  newLayout.insert(newIndex, item);
                  context.read<SettingsCubit>().updateDashboardLayout(newLayout);
                },
                itemBuilder: (context, index) {
                  final widgetType = layout[index];
                  final isVisible = !hidden.contains(widgetType);

                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(widgetType),
                    index: index,
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.drag_indicator, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        title: Text(widgetType.label),
                        trailing: Switch(
                          value: isVisible,
                          onChanged: (value) {
                            context.read<SettingsCubit>().toggleWidgetVisibility(widgetType, value);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
            ],
          );
        },
      ),
    );
  }
}
