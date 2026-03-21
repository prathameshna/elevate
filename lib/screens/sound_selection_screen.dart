import 'dart:convert';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sound_item.dart';
import '../models/my_music_track.dart';
import '../widgets/alarm_toggle.dart';

class SoundSelectionScreen extends StatefulWidget {
  final String? initialSoundId;

  const SoundSelectionScreen({super.key, this.initialSoundId});

  @override
  State<SoundSelectionScreen> createState() => _SoundSelectionScreenState();
}

class _SoundSelectionScreenState extends State<SoundSelectionScreen> {

  // ── State ─────────────────────────────────────────────────
  bool    _soundEnabled   = true;
  bool    _isMuted        = false;
  String  _activeTab      = 'Ringtones';
  String  _activeCategory = 'Bright';
  String? _selectedSoundId;
  String? _previewingFile;
  bool    _isRandom       = false;
  bool    _gradualVolume  = true;
  double  _volume         = 0.8;
  AudioPlayer? _audioPlayer;

  // My Music state
  List<MyMusicTrack> _myMusicTracks = [];
  bool _isLoadingMusic = false;

  // Category data: (label, icon)
  static const List<(String, IconData)> _categories = [
    ('Bright',    Icons.wb_sunny_rounded),
    ('Noisy',     Icons.volume_up_rounded),
    ('Energetic', Icons.bolt_rounded),
    ('Calm',      Icons.coffee_rounded),
    ('Alarm',     Icons.alarm_rounded),
    ('Fun',       Icons.sentiment_very_satisfied_rounded),
    ('Others',    Icons.notifications_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSoundId = widget.initialSoundId;
    
    // ✅ FIX: Find category of initialSoundId if provided
    if (_selectedSoundId != null && _selectedSoundId!.isNotEmpty) {
      if (_selectedSoundId!.startsWith('my_')) {
        _activeTab = 'My Music';
      } else {
        bool found = false;
        for (final entry in soundLibrary.entries) {
          if (entry.value.any((s) => s.id == _selectedSoundId)) {
            _activeCategory = entry.key;
            found = true;
            break;
          }
        }
        if (!found) {
          // Fallback check by file
          for (final entry in soundLibrary.entries) {
            for (final track in _myMusicTracks) { // This might be empty here as it's async
               // ... but we check library first
            }
          }
        }
      }
    }

    _loadSoundEnabled();
    _loadMyMusicTracks();
  }

  @override
  void dispose() {
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    super.dispose();
  }

  // ── My Music Persistence ──────────────────────────────────

  Future<void> _loadMyMusicTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getStringList('my_music_tracks') ?? [];
      setState(() {
        _myMusicTracks = encoded
            .map((e) => MyMusicTrack.fromJson(jsonDecode(e)))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _saveMyMusicTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _myMusicTracks
        .map((t) => jsonEncode(t.toJson()))
        .toList();
    await prefs.setStringList('my_music_tracks', encoded);
  }

  // ── Sound Settings Persistence ────────────────────────────

  Future<void> _loadSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }

  Future<void> _setSoundEnabled(bool value) async {
    setState(() {
      _soundEnabled = value;
      if (!value) _isMuted = false;
    });
    if (!value) {
      await _stopPreview();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
  }

  Future<void> _toggleMute() async {
    HapticFeedback.lightImpact();
    setState(() => _isMuted = !_isMuted);
    // Note: alarm preview volume doesn't have a direct mute-toggle while running
    // but we respect _isMuted globally if needed.
  }

  Future<void> _previewSound(String soundFile) async {
    if (!_soundEnabled) return;
    await _stopPreview();
    setState(() => _previewingFile = soundFile);

    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setAsset('assets/sounds/$soundFile');
      await _audioPlayer!.setVolume(_volume);
      await _audioPlayer!.play();

      // Auto stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), _stopPreview);
    } catch (e) {
      setState(() => _previewingFile = null);
    }
  }

  Future<void> _stopPreview() async {
    await _audioPlayer?.stop();
    await _audioPlayer?.dispose();
    _audioPlayer = null;
    if (mounted) setState(() => _previewingFile = null);
  }

  // ── Helpers ───────────────────────────────────────────────

  List<SoundItem> get _currentSounds =>
      soundLibrary[_activeCategory] ?? [];

  void _onRandomTap() {
    HapticFeedback.lightImpact();
    final sounds = _currentSounds;
    if (sounds.isEmpty) return;
    setState(() => _isRandom = !_isRandom);
    if (_isRandom) {
      final pick = sounds[Random().nextInt(sounds.length)];
      setState(() => _selectedSoundId = pick.id);
      _previewSound(pick.file);
    }
  }

  Future<void> _pickAudioFile() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoadingMusic = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final path = file.path;
        if (path == null) return;

        // Get clean display name (remove extension)
        final rawName = file.name;
        final displayName = rawName.contains('.')
            ? rawName.substring(0, rawName.lastIndexOf('.'))
            : rawName;

        final track = MyMusicTrack(
          id: 'my_${DateTime.now().millisecondsSinceEpoch}',
          name: displayName,
          filePath: path,
        );

        setState(() => _myMusicTracks.add(track));
        await _saveMyMusicTracks();

        // Auto-select and preview the new track
        setState(() => _selectedSoundId = track.id);
        _previewSound(track.filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick file: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingMusic = false);
    }
  }

  Future<void> _deleteMyMusicTrack(MyMusicTrack track) async {
    HapticFeedback.mediumImpact();
    if (_selectedSoundId == track.id) {
      setState(() => _selectedSoundId = null);
    }
    if (_previewingFile == track.filePath) {
      await _stopPreview();
    }
    setState(() => _myMusicTracks.removeWhere((t) => t.id == track.id));
    await _saveMyMusicTracks();
  }

  Map<String, String>? _buildResult() {
    if (_selectedSoundId == null) return null;
    // Find the actual filename for this sound id
    String? file;
    for (final sounds in soundLibrary.values) {
      for (final s in sounds) {
        if (s.id == _selectedSoundId) {
          file = s.file;
          break;
        }
      }
      if (file != null) break;
    }
    return {
      'id':   _selectedSoundId!,
      'file': file ?? 'alarm_ringtone.mp3',
    };
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFF5F5F5), size: 20),
          onPressed: () => Navigator.pop(context, _buildResult()),
        ),
        title: const Text('Sound',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          )),
        centerTitle: false,
      ),

      // ── Bottom sticky section ──
      bottomNavigationBar: _buildBottomSection(),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Enable Sound toggle
          _buildEnableSoundCard(),

          // Tabs
          _buildTabs(),

          const SizedBox(height: 4),

          // Only show for Ringtones tab
          if (_activeTab == 'Ringtones') ...[
            // Category chips
            _buildCategoryChips(),

            const SizedBox(height: 8),

            // Random row
            _buildRandomRow(),

            const SizedBox(height: 4),
          ],

          // Content list
          Expanded(
            child: _activeTab == 'Ringtones'
                ? _buildSoundList()
                : _buildMyMusicContent(),
          ),
        ],
      ),
    );
  }

  // ── Enable Sound Card ─────────────────────────────────────

  Widget _buildEnableSoundCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        children: [
          const Text('Enable Sound',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            )),
          const Spacer(),
          AlarmToggle(
            value: _soundEnabled,
            onChanged: _setSoundEnabled,
          ),
        ],
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: ['Ringtones', 'My Music'].map<Widget>((tab) {
          final isActive = _activeTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFFFFD600)
                        : const Color(0xFF606060),
                    fontSize: 16,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  child: Text(tab),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: isActive ? 64 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          );
        }).toList()
          ..insert(1, const SizedBox(width: 24)),
      ),
    );
  }

  // ── Category Chips ────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: _categories.map((cat) {
          final isActive = _activeCategory == cat.$1;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _activeCategory = cat.$1;
                _isRandom = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFFFD600).withValues(alpha: 0.12)
                    : const Color(0xFF242424),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFFFD600).withValues(alpha: 0.5)
                      : const Color(0xFF2E2E2E),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.$2,
                    size: 14,
                    color: isActive
                        ? const Color(0xFFFFD600)
                        : const Color(0xFF808080)),
                  const SizedBox(width: 6),
                  Text(cat.$1,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFFFD600)
                          : const Color(0xFF808080),
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Random Row ────────────────────────────────────────────

  Widget _buildRandomRow() {
    return GestureDetector(
      onTap: _onRandomTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isRandom
              ? const Color(0xFFFFD600).withValues(alpha: 0.08)
              : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isRandom
                ? const Color(0xFFFFD600).withValues(alpha: 0.4)
                : const Color(0xFF2E2E2E),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.shuffle_rounded,
              color: _isRandom
                  ? const Color(0xFFFFD600)
                  : const Color(0xFF808080),
              size: 20),
            const SizedBox(width: 12),
            Text('Random ($_activeCategory)',
              style: TextStyle(
                color: _isRandom
                    ? const Color(0xFFFFD600)
                    : const Color(0xFFF5F5F5),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              )),
          ],
        ),
      ),
    );
  }

  // ── Sound List ────────────────────────────────────────────

  Widget _buildSoundList() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: ListView.builder(
        key: ValueKey(_activeCategory),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _currentSounds.length,
        itemBuilder: (context, index) {
          final sound = _currentSounds[index];
          final isSelected = _selectedSoundId == sound.id;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedSoundId = sound.id;
                _isRandom = false;
              });
              if (_previewingFile == sound.file) {
                _stopPreview();
              } else {
                _previewSound(sound.file);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF2A2A2A),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Play/Stop preview button
                  IconButton(
                    icon: Icon(
                      _previewingFile == sound.file
                          ? Icons.stop_circle_rounded
                          : Icons.play_circle_rounded,
                      color: _previewingFile == sound.file
                          ? const Color(0xFFFFD600)
                          : const Color(0xFF606060),
                      size: 28,
                    ),
                    onPressed: () {
                      if (_previewingFile == sound.file) {
                        _stopPreview();
                      } else {
                        _previewSound(sound.file);
                      }
                    },
                  ),

                  const SizedBox(width: 8),

                  // Sound name
                  Expanded(
                    child: Text(
                      sound.name,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFFFD600)
                            : const Color(0xFFF5F5F5),
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),

                  // Selected checkmark
                  if (isSelected)
                    const Icon(Icons.check_rounded,
                        color: Color(0xFFFFD600), size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── My Music Content ──────────────────────────────────────

  Widget _buildMyMusicContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: ListView(
        key: const ValueKey('my_music'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [

          // "+ Add audio file" button
          GestureDetector(
            onTap: _isLoadingMusic ? null : _pickAudioFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3A3A3A),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: _isLoadingMusic
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFD600),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add_rounded,
                              color: Color(0xFFF5F5F5), size: 22),
                          SizedBox(width: 10),
                          Text('Add audio file',
                            style: TextStyle(
                              color: Color(0xFFF5F5F5),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            )),
                        ],
                      ),
              ),
            ),
          ),

          // Tracks list (shown below button when tracks exist)
          if (_myMusicTracks.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('My Tracks',
              style: TextStyle(
                color: Color(0xFF808080),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              )),
            const SizedBox(height: 10),
            ..._myMusicTracks.map((track) =>
              _buildMyMusicTrackRow(track)),
          ],

          // Empty state (no tracks yet, shown below button)
          if (_myMusicTracks.isEmpty) ...[
            const SizedBox(height: 32),
            const Icon(Icons.music_note_rounded,
                color: Color(0xFF3A3A3A), size: 48),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'No music added yet\nTap above to add your own alarm sound',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF505050),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyMusicTrackRow(MyMusicTrack track) {
    final isSelected = _selectedSoundId == track.id;

    return Dismissible(
      key: ValueKey(track.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.red, size: 22),
      ),
      onDismissed: (_) => _deleteMyMusicTrack(track),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedSoundId = track.id);
          if (_previewingFile == track.filePath) {
            _stopPreview();
          } else {
            _previewSound(track.filePath); // Using the same preview logic
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 4, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Play/Stop button
              IconButton(
                icon: Icon(
                  _previewingFile == track.filePath
                      ? Icons.stop_circle_rounded
                      : Icons.play_circle_rounded,
                  color: _previewingFile == track.filePath
                      ? const Color(0xFFFFD600)
                      : const Color(0xFF606060),
                  size: 28,
                ),
                onPressed: () {
                  if (_previewingFile == track.filePath) {
                    _stopPreview();
                  } else {
                    _previewSound(track.filePath);
                  }
                },
              ),
              const SizedBox(width: 8),

              // Track name
              Expanded(
                child: Text(
                  track.name,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFFD600)
                        : const Color(0xFFF5F5F5),
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Checkmark when selected
              if (isSelected)
                const Icon(Icons.check_rounded,
                    color: Color(0xFFFFD600), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Section ────────────────────────────────────────

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Gradually increase volume toggle
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _soundEnabled ? 1.0 : 0.35,
            child: IgnorePointer(
              ignoring: !_soundEnabled,
              child: Row(
                children: [
                  const Text('Gradually increase volume',
                    style: TextStyle(
                      color: Color(0xFFF5F5F5),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    )),
                  const Spacer(),
                  AlarmToggle(
                    value: _gradualVolume,
                    onChanged: (v) => setState(() => _gradualVolume = v),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Volume slider row
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _soundEnabled ? 1.0 : 0.35,
            child: IgnorePointer(
              ignoring: !_soundEnabled,
              child: Row(
                children: [

                  // ── Speaker icon (tappable mute) ──
                  GestureDetector(
                    onTap: _soundEnabled ? _toggleMute : null,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        key: ValueKey(_isMuted),
                        color: _isMuted
                            ? const Color(0xFF606060)
                            : const Color(0xFFFFD600),
                        size: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── Volume slider ──
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _isMuted
                            ? const Color(0xFF3A3A3A)   // grey when muted
                            : const Color(0xFFF5F5F5),
                        inactiveTrackColor: const Color(0xFF3A3A3A),
                        thumbColor: Colors.white,
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 18),
                        overlayColor: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: _volume,
                        min: 0,
                        max: 1,
                        onChanged: (v) {
                          setState(() => _volume = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

