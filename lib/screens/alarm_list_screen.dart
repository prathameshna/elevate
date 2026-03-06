import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_card.dart';
import '../widgets/expandable_fab.dart';
import 'edit_alarm_screen.dart';
import 'quick_alarm_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  List<Alarm> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    await AlarmService.instance.init();
    if (mounted) {
      setState(() {
        _alarms = AlarmService.instance.alarms.toList();
        _isLoading = false;
      });
    }
  }

  void _refreshAlarms() {
    setState(() {
      _alarms = AlarmService.instance.alarms.toList();
    });
  }

  Future<void> _openNewAlarm(BuildContext context) async {
    final result = await Navigator.push<Alarm>(
      context,
      _smoothSlideRoute(const EditAlarmScreen()),
    );
    if (result != null && mounted) _refreshAlarms();
  }

  Future<void> _openEditAlarm(BuildContext context, Alarm alarm) async {
    final result = await Navigator.push<Alarm>(
      context,
      _smoothSlideRoute(EditAlarmScreen(alarmId: alarm.id)),
    );
    if (result != null && mounted) _refreshAlarms();
  }

  PageRouteBuilder<T> _smoothSlideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
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

  Future<void> _confirmDelete(BuildContext context, Alarm alarm) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Delete alarm?'),
        content: const Text(
          'This alarm will be removed and will no longer trigger.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: ElevateTheme.warning),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AlarmService.instance.deleteAlarm(alarm.id);
      _refreshAlarms();
    }
  }

  Future<void> _toggleAlarm(String id, bool isEnabled) async {
    await AlarmService.instance.toggleAlarm(id, isEnabled);
    _refreshAlarms();
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
                        if (_isLoading) {
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final alarm = _alarms[index];
                            return AlarmCard(
                              alarm: alarm,
                              onToggle: (newValue) => _toggleAlarm(alarm.id, newValue),
                              onTap: () => _openEditAlarm(context, alarm),
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
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickAlarmScreen(),
                  fullscreenDialog: true,
                ),
              );
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

