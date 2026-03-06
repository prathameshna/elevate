import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/mission.dart';

class MissionCard extends StatefulWidget {
  final Mission mission;
  final Function(Mission) onMissionUpdated;

  const MissionCard({
    Key? key,
    required this.mission,
    required this.onMissionUpdated,
  }) : super(key: key);

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard>
    with SingleTickerProviderStateMixin {
  late Set<int> _selectedDays;
  late bool _wakeUpCheckEnabled;
  late AnimationController _containerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDays = Set<int>.from(widget.mission.selectedDays);
    _wakeUpCheckEnabled = widget.mission.enableWakeUpCheck;

    _containerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _containerController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _containerController, curve: Curves.easeOut),
    );

    _containerController.forward();
  }

  @override
  void dispose() {
    _containerController.dispose();
    super.dispose();
  }

  void _handleDaysSelected(Set<int> days) {
    if (!mounted) return;
    setState(() => _selectedDays = days);
    final updatedMission = widget.mission.copyWith(
      selectedDays: days,
    );
    widget.onMissionUpdated(updatedMission);
  }

  void _handleWakeUpToggle(bool enabled) {
    if (!mounted) return;
    setState(() => _wakeUpCheckEnabled = enabled);
    final updatedMission = widget.mission.copyWith(
      enableWakeUpCheck: enabled,
    );
    widget.onMissionUpdated(updatedMission);
  }

  void _handleMissionSlotTap(int index) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final updatedMission = widget.mission.copyWith(
      completedSlots: index + 1,
    );
    widget.onMissionUpdated(updatedMission);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
// ...
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3A3A3A)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.mission.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF5F5F5),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.mission.completedSlots}/${widget.mission.maxSlots}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFD600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // MISSION GRID
              _buildMissionGrid(),
              const SizedBox(height: 20),

              // DIVIDER
              Container(
                height: 1,
                color: const Color(0xFF3A3A3A),
              ),
              const SizedBox(height: 16),

              // QUICK SELECT LABEL
              const Text(
                'Quick Select',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFA0A0A0),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // QUICK SELECT BUTTONS - RESPONSIVE
              _buildQuickSelectButtons(),
              const SizedBox(height: 16),

              // DAY SELECTOR - RESPONSIVE
              _buildDaySelector(),
              const SizedBox(height: 16),

              // DIVIDER
              Container(
                height: 1,
                color: const Color(0xFF3A3A3A),
              ),
              const SizedBox(height: 16),

              // WAKE-UP CHECK TOGGLE
              _buildWakeUpCheckToggle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const spacing = 8.0;
        final buttonSize = (availableWidth - (spacing * 3)) / 4;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                final isCompleted = index < widget.mission.completedSlots;
                return _buildMissionButton(
                  index: index,
                  isCompleted: isCompleted,
                  size: buttonSize,
                );
              }),
            ),
            if (widget.mission.maxSlots > 4) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMissionButton(
                    index: 4,
                    isCompleted: 4 < widget.mission.completedSlots,
                    size: buttonSize,
                  ),
                  SizedBox(width: buttonSize + spacing),
                  SizedBox(width: buttonSize + spacing),
                  SizedBox(width: buttonSize + spacing),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMissionButton({
    required int index,
    required bool isCompleted,
    required double size,
  }) {
    return GestureDetector(
      onTap: () => _handleMissionSlotTap(index),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFF14B8A6) : const Color(0xFF1A1A1A),
          border: Border.all(
            color: const Color(0xFF3A3A3A),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 24)
              : Text(
                  '+',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFFA0A0A0),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildQuickSelectButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickSelectButton('Daily', _selectedDays.length == 7),
          const SizedBox(width: 8),
          _buildQuickSelectButton('Weekdays', _selectedDays.length == 5 && !_selectedDays.contains(0) && !_selectedDays.contains(6)),
          const SizedBox(width: 8),
          _buildQuickSelectButton('Weekends', _selectedDays.length == 2 && _selectedDays.contains(0) && _selectedDays.contains(6)),
        ],
      ),
    );
  }

  Widget _buildQuickSelectButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Set<int> newDays;
        if (label == 'Daily') {
          newDays = {0, 1, 2, 3, 4, 5, 6};
        } else if (label == 'Weekdays') {
          newDays = {1, 2, 3, 4, 5};
        } else {
          newDays = {0, 6};
        }
        _handleDaysSelected(newDays);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF14B8A6) : const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF3A3A3A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFA0A0A0),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final dayButtonSize = (constraints.maxWidth - (6 * 4)) / 7;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final isSelected = _selectedDays.contains(index);
            return GestureDetector(
              onTap: () {
                final newDays = Set<int>.from(_selectedDays);
                if (newDays.contains(index)) {
                  newDays.remove(index);
                } else {
                  newDays.add(index);
                }
                _handleDaysSelected(newDays);
              },
              child: Container(
                width: dayButtonSize,
                height: dayButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF14B8A6) : const Color(0xFF3A3A3A),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFFD600) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    dayLabels[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFA0A0A0),
                      fontSize: dayButtonSize * 0.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildWakeUpCheckToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.lock, color: Color(0xFFA0A0A0), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Wake up check',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'HOT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          Switch(
            value: _wakeUpCheckEnabled,
            onChanged: _handleWakeUpToggle,
            activeColor: const Color(0xFF14B8A6),
            inactiveThumbColor: const Color(0xFF3A3A3A),
          ),
        ],
      ),
    );
  }
}
