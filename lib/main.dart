import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'providers/alarm_provider.dart';
import 'alarm/alarm_manager.dart';
import 'services/alarm_storage.dart';
import 'screens/alarm_list_screen.dart';
import 'screens/shell_screens.dart';
import 'screens/ringing_screen.dart';
import 'theme/app_theme.dart';

// Global navigator key - MUST be at top level
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Alarm package
  await AlarmManager.initialize();

  // Request exact alarm permission (Android 12+)
  final hasPermission = await AlarmManager.checkPermission();
  if (!hasPermission) {
    await AlarmManager.requestPermission();
  }

  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  runApp(const ElevateApp());
}

class ElevateApp extends StatefulWidget {
  const ElevateApp({super.key});

  @override
  State<ElevateApp> createState() => _ElevateAppState();
}

class _ElevateAppState extends State<ElevateApp> {
  StreamSubscription<alarm_pkg.AlarmSettings>? _alarmSub;

  @override
  void initState() {
    super.initState();
    _alarmSub = alarm_pkg.Alarm.ringStream.stream.listen((alarm_pkg.AlarmSettings settings) async {
      final alarm = await AlarmStorage.getByNumericId(settings.id);
      if (alarm == null) return;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => RingingScreen(
            alarm:         alarm,
            alarmSettings: settings,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _alarmSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AlarmProvider(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // ← MUST have this
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

