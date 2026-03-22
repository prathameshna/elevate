import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'typing_mission_model.dart';

class TypingChallengeScreen extends StatefulWidget {
  final TypingMissionConfig config;
  final VoidCallback onComplete;

  const TypingChallengeScreen({
    super.key,
    required this.config,
    required this.onComplete,
  });

  @override
  State<TypingChallengeScreen> createState() => _TypingChallengeScreenState();
}

class _TypingChallengeScreenState extends State<TypingChallengeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late List<String> _selectedSentences;
  final TextEditingController _controller = TextEditingController();
  
  bool _isSuccess = false;
  bool _isWrong = false;
  
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    
    // Pick random sentences
    final random = Random();
    final allSentences = List<String>.from(TypingMissionConfig.kSentences);
    allSentences.shuffle(random);
    _selectedSentences = allSentences.take(widget.config.taskCount).toList();
    
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    _checkController.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    if (_isSuccess) return;

    final target = _selectedSentences[_currentIndex];
    
    // Strict matching logic
    if (value == target) {
      _handleSuccess();
    } else {
      setState(() {
        _isWrong = value.length >= target.length && value != target;
      });
    }
  }

  void _handleSuccess() {
    setState(() {
      _isSuccess = true;
      _isWrong = false;
    });
    
    HapticFeedback.heavyImpact();
    _checkController.forward();
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      
      _checkController.reset();
      _controller.clear();
      
      if (_currentIndex < _selectedSentences.length - 1) {
        setState(() {
          _currentIndex++;
          _isSuccess = false;
        });
      } else {
        widget.onComplete();
      }
    });
  }

  List<TextSpan> _buildTargetSpans() {
    final String target = _selectedSentences[_currentIndex];
    final String input = _controller.text;
    final List<TextSpan> spans = [];

    final int maxLength = input.length > target.length 
        ? input.length 
        : target.length;

    for (int i = 0; i < maxLength; i++) {
      String char;
      Color color;
      FontWeight weight = FontWeight.w700;

      if (i < input.length) {
        char = input[i];
        if (i < target.length) {
          if (char == target[i]) {
            color = const Color(0xFF22C55E); // Success Green
          } else {
            color = const Color(0xFFEF4444); // Error Red
          }
        } else {
          color = const Color(0xFFEF4444); // Extra char Red
        }
      } else {
        char = target[i];
        color = const Color(0xFF606060); // Dimmed Gray
        weight = FontWeight.w500;
      }

      spans.add(TextSpan(
        text: char,
        style: TextStyle(
          color: color,
          fontSize: 32,
          fontWeight: weight,
          letterSpacing: -0.5,
        ),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final target = _selectedSentences[_currentIndex];
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Progress Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Task ${_currentIndex + 1} of ${_selectedSentences.length}',
                        style: const TextStyle(
                          color: Color(0xFF808080),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Icon(Icons.keyboard_rounded, 
                          color: Color(0xFF808080), size: 20),
                    ],
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Sentence Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF252525)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(children: _buildTargetSpans()),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Input Field
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        controller: _controller,
                        onChanged: _onInputChanged,
                        autofocus: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          color: Color(0xFFF0F0F0),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type exactly...',
                          hintStyle: const TextStyle(color: Color(0xFF444444)),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _isSuccess 
                                  ? const Color(0xFF22C55E) 
                                  : (_isWrong ? const Color(0xFFEF4444) : const Color(0xFF252525)),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _isSuccess 
                                  ? const Color(0xFF22C55E) 
                                  : (_isWrong ? const Color(0xFFEF4444) : const Color(0xFFFFD600)),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                      ),
                      
                      // Success Checkmark
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ScaleTransition(
                          scale: _checkScale,
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF22C55E),
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Hint/Validation feedback
                  Text(
                    _isSuccess 
                        ? 'Correct!' 
                        : (_isWrong ? 'Double check spelling/case' : 'Pay attention to uppercase and spaces'),
                    style: TextStyle(
                      color: _isSuccess 
                          ? const Color(0xFF22C55E) 
                          : (_isWrong ? const Color(0xFFEF4444) : const Color(0xFF606060)),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
