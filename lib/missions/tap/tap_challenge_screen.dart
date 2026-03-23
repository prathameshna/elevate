import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tap_mission_model.dart';

class TapChallengeScreen extends StatefulWidget {
  final TapMissionConfig config;
  final VoidCallback onComplete;
  final bool isPreview;

  const TapChallengeScreen({
    super.key,
    required this.config,
    required this.onComplete,
    this.isPreview = false,
  });

  @override
  State<TapChallengeScreen> createState() => _TapChallengeScreenState();
}

class _TapChallengeScreenState extends State<TapChallengeScreen> with TickerProviderStateMixin {
  int _currentTapCount = 0;
  int _secondsLeft = 0;
  int _countdownSeconds = 3;
  bool _isCountdownActive = false;
  bool _isChallengeActive = false;
  bool _isFinished = false;
  bool _isSuccess = false;
  bool _isWaitingToStart = true;

  Timer? _timer;
  late AnimationController _pulseController;
  late AnimationController _fireworksController;
  final List<_FireworkParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.config.seconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fireworksController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(_updateParticles);
  }

  void _startMission() {
    setState(() {
      _isWaitingToStart = false;
      _isCountdownActive = true;
    });
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _fireworksController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 1) {
          _countdownSeconds--;
          HapticFeedback.lightImpact();
        } else {
          _timer?.cancel();
          _isCountdownActive = false;
          _isChallengeActive = true;
          _startChallenge();
        }
      });
    });
  }

  void _startChallenge() {
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
          _isChallengeActive = false;
          _finishChallenge();
        }
      });
    });
  }

  void _onTap() {
    if (!_isChallengeActive || _isFinished) return;

    setState(() {
      _currentTapCount++;
      _pulseController.forward(from: 0);
      HapticFeedback.selectionClick();

      if (_currentTapCount >= widget.config.tapCount) {
        _timer?.cancel();
        _isChallengeActive = false;
        _isSuccess = true;
        _finishChallenge();
      }
    });
  }

  void _finishChallenge() {
    setState(() {
      _isFinished = true;
      if (_isSuccess) {
        _startFireworks();
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  void _startFireworks() {
    _fireworksController.repeat();
    _createExplosion();
  }

  void _createExplosion() {
    final random = math.Random();
    for (int i = 0; i < 5; i++) {
        final x = random.nextDouble() * 400;
        final y = random.nextDouble() * 600;
        final color = Colors.primaries[random.nextInt(Colors.primaries.length)];
        for (int j = 0; j < 30; j++) {
            _particles.add(_FireworkParticle(
                x: x,
                y: y,
                vx: (random.nextDouble() - 0.5) * 10,
                vy: (random.nextDouble() - 0.5) * 10,
                color: color,
                life: 1.0,
            ));
        }
    }
  }

  void _updateParticles() {
    setState(() {
      for (int i = _particles.length - 1; i >= 0; i--) {
        _particles[i].update();
        if (_particles[i].life <= 0) {
          _particles.removeAt(i);
        }
      }
      if (_particles.isEmpty && _isSuccess) {
          _createExplosion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Fireworks Background
          if (_isSuccess)
            Positioned.fill(
              child: CustomPaint(
                painter: _FireworksPainter(_particles),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                // Start Button
                if (_isWaitingToStart)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded, color: Color(0xFFFFD600), size: 80),
                        const SizedBox(height: 20),
                        const Text(
                          'TAP CHALLENGE',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tap ${widget.config.tapCount} times in ${widget.config.seconds}s',
                          style: const TextStyle(color: Color(0xFF606060), fontSize: 16),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _startMission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD600),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('START', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        ),
                      ],
                    ),
                  ),

                // Countdown Overlay
                if (_isCountdownActive)
                  Center(
                    child: Text(
                      '$_countdownSeconds',
                      style: const TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                // Challenge UI
                if (_isChallengeActive || (_isFinished && !_isSuccess))
                  _buildChallengeUI(),

                // Success Message
                if (_isFinished && _isSuccess)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFFFFD600), size: 100),
                        const SizedBox(height: 20),
                        const Text(
                          'SUCCESS!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_currentTapCount TAPS COMPLETED',
                          style: const TextStyle(
                            color: Color(0xFFA0A0A0),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),
                
                // Tap Button
                if (_isChallengeActive)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: GestureDetector(
                      onTapDown: (_) => _onTap(),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 0.9).animate(_pulseController),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD600), Color(0xFFFFB300)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD600).withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'TAP!',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Retry Button if failed
                if (_isFinished && !_isSuccess && !widget.isPreview)
                   Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentTapCount = 0;
                          _secondsLeft = widget.config.seconds;
                          _countdownSeconds = 3;
                          _isCountdownActive = true;
                          _isChallengeActive = false;
                          _isFinished = false;
                          _isSuccess = false;
                        });
                        _startCountdown();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD600),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('RETRY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
              ],
            ),
          ),
          
          // Close button for preview
          if (widget.isPreview)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengeUI() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('TIME', '$_secondsLeft', Colors.redAccent),
            _buildStatCard('TAPS', '$_currentTapCount/${widget.config.tapCount}', const Color(0xFFFFD600)),
          ],
        ),
        const SizedBox(height: 40),
        if (_isFinished && !_isSuccess)
          const Text(
            'TOO SLOW!',
            style: TextStyle(color: Colors.redAccent, fontSize: 40, fontWeight: FontWeight.w900),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FireworkParticle {
  double x, y, vx, vy, life;
  Color color;

  _FireworkParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.1; // gravity
    life -= 0.02;
  }
}

class _FireworksPainter extends CustomPainter {
  final List<_FireworkParticle> particles;

  _FireworksPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withValues(alpha: p.life);
      canvas.drawCircle(Offset(p.x, p.y), 3 * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
