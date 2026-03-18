import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_card.dart';
import '../widgets/expandable_fab.dart';
import '../services/alarm_storage.dart';
import '../alarm/alarm_manager.dart';
import 'edit_alarm_screen.dart';
import 'quick_alarm_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  List<Alarm> _alarms = [];
  bool        _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    final alarms = await AlarmStorage.loadList();
    if (mounted) {
      setState(() {
        _alarms  = alarms;
        _loading = false;
      });
    }
  }

  Future<void> _openNewAlarm(BuildContext context) async {
    Navigator.push(
      context,
      _smoothSlideRoute(const EditAlarmScreen()),
    ).then((_) => _loadAlarms()); // ← reload when done
  }

  Future<void> _openEditAlarm(BuildContext context, Alarm alarm) async {
    Navigator.push(
      context,
      _smoothSlideRoute(EditAlarmScreen(alarmId: alarm.id)),
    ).then((_) => _loadAlarms()); // ← reload when done
  }

  // Toggle alarm on/off
  Future<void> _toggleAlarm(Alarm alarm) async {
    final updated = alarm.copyWith(isEnabled: !alarm.isEnabled);
    await AlarmStorage.save(updated);
    if (updated.isEnabled) {
      await AlarmManager.schedule(updated);
    } else {
      await AlarmManager.cancel(updated);
    }
    _loadAlarms(); // refresh list
  }

  // Delete alarm
  Future<void> _deleteAlarm(Alarm alarm) async {
    await AlarmManager.cancel(alarm);
    await AlarmStorage.delete(alarm.id);
    _loadAlarms(); // refresh list
  }

  PageRouteBuilder<T> _smoothSlideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, animation, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
          ),
        );

        final scale = Tween<double>(begin: 0.97, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: SlideTransition(position: slide, child: child),
          ),
        );
      },
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
                    child: Builder(
                      builder: (context) {
                        if (_loading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (_alarms.isEmpty) {
                          return _EmptyState(theme: theme);
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: _alarms.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final alarm = _alarms[index];
                            return AlarmCard(
                              alarm: alarm,
                              onToggle: (_) => _toggleAlarm(alarm),
                              onTap: () => _openEditAlarm(context, alarm),
                              onDelete: () => _deleteAlarm(alarm),
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
            onAlarm: () => _openNewAlarm(context),
            onQuickAlarm: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickAlarmScreen(),
                  fullscreenDialog: true,
                ),
              );
              _loadAlarms(); // refresh after quick alarm
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
            color: ElevateTheme.accent.withValues(alpha: 0.7),
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

