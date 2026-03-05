import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/alarm_provider.dart';
import '../theme/app_theme.dart';

class QuickAlarmScreen extends StatefulWidget {
  const QuickAlarmScreen({super.key});

  @override
  State<QuickAlarmScreen> createState() => _QuickAlarmScreenState();
}

class _QuickAlarmScreenState extends State<QuickAlarmScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDuration = 0;
  double _volume = 50;
  bool _vibration = true;
  bool _isLoading = false;

  late final AnimationController _staggerController;
  late final List<Animation<double>> _staggerAnimations;

  final List<int> _durations = [1, 5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _staggerAnimations = List.generate(
      5, // Header, Time, Grid, Volume, Save
      (index) => CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          index * 0.1,
          0.6 + index * 0.1,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _handleDurationSelect(int duration) {
    if (_isLoading) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDuration = duration;
    });
  }

  Future<void> _handleSave() async {
    if (_selectedDuration == 0 || _isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final provider = context.read<AlarmProvider>();
      final now = DateTime.now();
      final alarmTime = now.add(Duration(minutes: _selectedDuration));
      
      final timeOfDay = TimeOfDay(
        hour: alarmTime.hour,
        minute: alarmTime.minute,
      );

      final alarm = provider.createNewForTime(timeOfDay).copyWith(
        label: 'Quick Alarm (+${_selectedDuration}m)',
        volume: _volume.toInt(),
        vibration: _vibration,
      );

      await provider.addAlarm(alarm);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create alarm: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: FadeTransition(
          opacity: _staggerAnimations[0],
          child: ScaleTransition(
            scale: _staggerAnimations[0],
            child: const Text('Quick alarm'),
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              
              // Time Display
              FadeTransition(
                opacity: _staggerAnimations[1],
                child: ScaleTransition(
                  scale: _staggerAnimations[1],
                  child: Text(
                    '+ $_selectedDuration m',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Duration Grid
              FadeTransition(
                opacity: _staggerAnimations[2],
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: _durations.length,
                  itemBuilder: (context, index) {
                    final d = _durations[index];
                    final isSelected = _selectedDuration == d;
                    return _DurationButton(
                      label: '+$d m',
                      isSelected: isSelected,
                      onTap: () => _handleDurationSelect(d),
                    );
                  },
                ),
              ),

              const SizedBox(height: 48),

              // Volume & Vibration
              FadeTransition(
                opacity: _staggerAnimations[3],
                child: _VolumeControl(
                  volume: _volume,
                  vibration: _vibration,
                  onVolumeChanged: (v) {
                    setState(() => _volume = v);
                    if (v.toInt() % 10 == 0) {
                      HapticFeedback.lightImpact();
                    }
                  },
                  onVibrationChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _vibration = v);
                  },
                ),
              ),

              const Spacer(),

              // Save Button
              FadeTransition(
                opacity: _staggerAnimations[4],
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedDuration > 0 ? _handleSave : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ElevateTheme.quick,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: ElevateTheme.quick.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: isSelected ? ElevateTheme.quick : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.tealAccent : const Color(0xFF3A3A3A),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ElevateTheme.quick.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFFF5F5F5),
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumeControl extends StatelessWidget {
  final double volume;
  final bool vibration;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onVibrationChanged;

  const _VolumeControl({
    required this.volume,
    required this.vibration,
    required this.onVolumeChanged,
    required this.onVibrationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.volume_up_rounded,
              color: ElevateTheme.warning.withOpacity(volume / 100),
              size: 24,
            ),
            Expanded(
              child: Slider(
                value: volume,
                min: 0,
                max: 100,
                activeColor: ElevateTheme.quick,
                inactiveColor: const Color(0xFF3A3A3A),
                onChanged: onVolumeChanged,
              ),
            ),
            GestureDetector(
              onTap: () => onVibrationChanged(!vibration),
              child: Icon(
                Icons.vibration_rounded,
                color: vibration ? ElevateTheme.warning : Colors.grey,
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
