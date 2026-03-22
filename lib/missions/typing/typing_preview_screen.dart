import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'typing_mission_model.dart';

class TypingPreviewScreen extends StatefulWidget {
  const TypingPreviewScreen({super.key});

  @override
  State<TypingPreviewScreen> createState() => _TypingPreviewScreenState();
}

class _TypingPreviewScreenState extends State<TypingPreviewScreen> {
  late String _targetSentence;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Use a random sentence or the first one for preview
    _targetSentence = TypingMissionConfig.kSentences[0];
    
    // Auto focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    setState(() {}); // Trigger rebuild to update character colors
    
    if (value == _targetSentence) {
      // Success feedback
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfect! You matched the sentence.', 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFFD600),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Delay slightly then reset or just let them stay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
           _controller.clear();
           setState(() {
             // Pick next sentence for variety
             final index = TypingMissionConfig.kSentences.indexOf(_targetSentence);
             _targetSentence = TypingMissionConfig.kSentences[(index + 1) % TypingMissionConfig.kSentences.length];
           });
        }
      });
    }
  }

  List<TextSpan> _buildTargetSpans() {
    final String input = _controller.text;
    final List<TextSpan> spans = [];

    // Iterate through characters
    final int maxLength = input.length > _targetSentence.length 
        ? input.length 
        : _targetSentence.length;

    for (int i = 0; i < maxLength; i++) {
      String char;
      Color color;
      FontWeight weight = FontWeight.w600;

      if (i < input.length) {
        // Character is typed
        char = input[i];
        
        if (i < _targetSentence.length) {
          // Check match
          if (char == _targetSentence[i]) {
            color = const Color(0xFF1D9B71); // Premium Green
          } else {
            color = const Color(0xFFFF4D4D); // Error Red
          }
        } else {
          // Extra characters typed (beyond target length)
          color = const Color(0xFFFF4D4D); 
        }
      } else {
        // Character not yet typed (from target)
        char = _targetSentence[i];
        color = const Color(0xFF404040); // Dimmed Gray
        weight = FontWeight.w400;
      }

      spans.add(TextSpan(
        text: char,
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: weight,
          letterSpacing: 0.5,
        ),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Typing Preview',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Instruction
              const Text(
                'TYPING PRACTICE',
                style: TextStyle(
                  color: Color(0xFFFFD600),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Type the sentence exactly as shown.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF808080),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Main Display Area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF252525)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(children: _buildTargetSpans()),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Hidden or minimal text field to drive the input
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onInputChanged,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      cursorColor: const Color(0xFFFFD600),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Start typing...',
                        hintStyle: TextStyle(color: Color(0xFF333333)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Helpful tip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9B71).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1D9B71).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF1D9B71), size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Validation is case-sensitive and counts every character including spaces.',
                        style: TextStyle(color: Color(0xFF1D9B71), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
