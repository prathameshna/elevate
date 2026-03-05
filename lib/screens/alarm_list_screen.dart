import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_card.dart';
import '../widgets/expandable_fab.dart';
import 'edit_alarm_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AlarmProvider>().initialize(),
    );
  }

  Future<void> _openNewAlarm(BuildContext context) async {
    final provider = context.read<AlarmProvider>();
    final now = TimeOfDay.now();
    final alarm = provider.createNewForTime(now);
    final result = await Navigator.of(context).push<Alarm>(
      MaterialPageRoute(
        builder: (_) => EditAlarmScreen(
          alarm: alarm,
          isNew: true,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      await provider.addAlarm(result);
    }
  }

  Future<void> _editAlarm(BuildContext context, Alarm alarm) async {
    final provider = context.read<AlarmProvider>();
    final result = await Navigator.of(context).push<Alarm>(
      MaterialPageRoute(
        builder: (_) => EditAlarmScreen(
          alarm: alarm,
          isNew: false,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      await provider.updateAlarm(result);
    }
  }

  void _confirmDelete(BuildContext context, Alarm alarm) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Delete alarm?'),
        content: const Text(
          'This alarm will be removed and will no longer trigger.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AlarmProvider>().deleteAlarm(alarm.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: ElevateTheme.warning),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Elevate',
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your alarms, elevated.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Consumer<AlarmProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (provider.alarms.isEmpty) {
                          return _EmptyState(theme: theme);
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: provider.alarms.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final alarm = provider.alarms[index];
                            return AlarmCard(
                              alarm: alarm,
                              onToggleChanged: (value) =>
                                  provider.toggleAlarm(
                                alarm.id,
                                value,
                              ),
                              onTap: () => _editAlarm(context, alarm),
                              onDelete: () => _confirmDelete(context, alarm),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ExpandableFab(
            onAlarm: () async {
              await _openNewAlarm(context);
            },
            onQuickAlarm: () async {
              final provider = context.read<AlarmProvider>();
              final now = TimeOfDay.now();
              var minute = now.minute + 5;
              var hour = now.hour;
              if (minute >= 60) {
                minute -= 60;
                hour = (hour + 1) % 24;
              }
              final quickTime = TimeOfDay(hour: hour, minute: minute);
              final alarm = provider
                  .createNewForTime(quickTime)
                  .copyWith(label: 'Quick alarm');
              await provider.addAlarm(alarm);
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.alarm,
            size: 56,
            color: ElevateTheme.accent.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No alarms yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the plus button to create your first alarm.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

