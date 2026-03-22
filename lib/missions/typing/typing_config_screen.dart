import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'typing_mission_model.dart';
import 'typing_preview_screen.dart';

class TypingConfigScreen extends StatefulWidget {
  final TypingMissionConfig? initialConfig;
  const TypingConfigScreen({super.key, this.initialConfig});

  @override
  State<TypingConfigScreen> createState() => _TypingConfigScreenState();
}

class _TypingConfigScreenState extends State<TypingConfigScreen> {
  late int _selectedCount;

  @override
  void initState() {
    super.initState();
    _selectedCount = widget.initialConfig?.taskCount ?? 3;
  }

  void _showPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TypingPreviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFF0F0F0), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Typing Mission',
            style: TextStyle(
                color: Color(0xFFF0F0F0),
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Description Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF252525)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, 
                            color: Color(0xFFFFD600), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Type the exact sentence shown — letter case and spaces must be perfect',
                            style: TextStyle(
                              color: Color(0xFFF0F0F0),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Task Count Selector
                  const Text(
                    'NUMBER OF TASKS',
                    style: TextStyle(
                      color: Color(0xFF808080),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final count = index + 1;
                      final isSelected = _selectedCount == count;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedCount = count);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: (MediaQuery.of(context).size.width - 48 - 40) / 5,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFD600) : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFFD600) : const Color(0xFF252525),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected ? Colors.black : const Color(0xFFF0F0F0),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Preview Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _showPreview,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF252525)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: const Color(0xFFF0F0F0),
                      ),
                      child: const Text(
                        'PREVIEW',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Confirm Button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, TypingMissionConfig(taskCount: _selectedCount));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD600),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'CONFIRM',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

