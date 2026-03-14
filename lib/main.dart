import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'providers/alarm_provider.dart';
import 'alarm/alarm_service.dart';
import 'alarm/alarm_scheduler.dart';
import 'services/alarm_service.dart' as db_service;
import 'screens/alarm_list_screen.dart';
import 'screens/shell_screens.dart';
import 'theme/app_theme.dart';

// ADD global navigator key
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the foreground task entry point
  FlutterForegroundTask.initCommunicationPort();

  // Init alarm service
  await AlarmService.instance.init();

  // Init scheduler
  await AlarmScheduler.instance.init();

  // Set navigator key for AlarmNavigator
  AlarmNavigator.navigatorKey = navigatorKey;

  // Reschedule all enabled alarms from DB
  try {
    await db_service.AlarmService.instance.init();
    final alarms = db_service.AlarmService.instance.alarms;
    for (final alarm in alarms) {
      if (alarm.isEnabled) {
        await AlarmScheduler.instance.schedule(alarm);
      }
    }
  } catch (e) {
    debugPrint('⚠️ Could not reschedule alarms: $e');
  }

  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  runApp(const ElevateApp());
}

class ElevateApp extends StatelessWidget {
  const ElevateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AlarmProvider(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Elevate',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ElevateTheme.darkTheme(context),
        home: const _RootScaffold(),
      ),
    );
  }
}

class _RootScaffold extends StatefulWidget {
  const _RootScaffold();

  @override
  State<_RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<_RootScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const AlarmListScreen(),
      const PlaceholderShellScreen(
        title: 'Tasks',
        icon: Icons.check_circle_outline,
      ),
      const PlaceholderShellScreen(
        title: 'Calendar',
        icon: Icons.calendar_today_outlined,
      ),
      const PlaceholderShellScreen(
        title: 'Focus',
        icon: Icons.brightness_low_outlined,
      ),
      const PlaceholderShellScreen(
        title: 'Profile',
        icon: Icons.person_outline,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_outlined),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            label: 'Task',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.brightness_low_outlined),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

