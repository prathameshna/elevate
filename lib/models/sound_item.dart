class SoundItem {
  final String id;
  final String name;
  final String file; // filename inside assets/sounds/

  const SoundItem({
    required this.id,
    required this.name,
    required this.file,
  });
}

// ── Sound library grouped by category ─────────────────────

const Map<String, List<SoundItem>> soundLibrary = {
  'Bright': [
    SoundItem(id: 'bright_1', name: 'Bright Bell', file: 'bright_bell.mp3'),
    SoundItem(id: 'bright_2', name: 'Phone Ringing', file: 'phone_ringing.mp3'),
    SoundItem(id: 'bright_3', name: 'Funny Summer', file: 'sting_funny_summer.mp3'),
    SoundItem(id: 'bright_4', name: 'Universfield Ringtone', file: 'universfield_ringtone.mp3'),
    SoundItem(id: 'bright_5', name: 'Wavy', file: 'wavy.mp3'),
  ],
  'Noisy': [
    SoundItem(id: 'noisy_1', name: 'Noisy 1', file: 'noisy1.mp3'),
    SoundItem(id: 'noisy_2', name: 'Noisy 2', file: 'noisy2.mp3'),
    SoundItem(id: 'noisy_3', name: 'Noisy 3', file: 'noisy3.mp3'),
    SoundItem(id: 'noisy_4', name: 'Noisy 4', file: 'noisy4.mp3'),
    SoundItem(id: 'noisy_5', name: 'Noisy 5', file: 'noisy5.mp3'),
    SoundItem(id: 'noisy_7', name: 'Noisy 7', file: 'noisy7.mp3'),
    SoundItem(id: 'noisy_8', name: 'Noisy 8', file: 'noisy8.mp3'),
    SoundItem(id: 'noisy_9', name: 'Noisy 9', file: 'noisy9.mp3'),
  ],
  'Energetic': [
    SoundItem(id: 'energetic_1', name: 'Energetic Dance', file: 'energetic_dance.mp3'),
    SoundItem(id: 'energetic_2', name: 'Fall', file: 'fall.mp3'),
    SoundItem(id: 'energetic_3', name: 'Rock Logo', file: 'rock_logo.mp3'),
    SoundItem(id: 'energetic_4', name: 'Soundreality Start', file: 'soundreality_start.mp3'),
    SoundItem(id: 'energetic_5', name: 'Sport Rock', file: 'sport_rock.mp3'),
    SoundItem(id: 'energetic_6', name: 'Vicatestudio Energetic', file: 'vicatestudio_energetic.mp3'),
  ],
  'Calm': [
    SoundItem(id: 'calm_1', name: 'Calm', file: 'calm.mp3'),
    SoundItem(id: 'calm_2', name: 'Calming Melody', file: 'calming_melody_loop.mp3'),
    SoundItem(id: 'calm_3', name: 'Flues', file: 'flues.mp3'),
    SoundItem(id: 'calm_4', name: 'Motivational Jazz', file: 'motivational_jazz_beat.mp3'),
    SoundItem(id: 'calm_5', name: 'Relaxing Cinematic Pads', file: 'relaxing_cinematic_pads.mp3'),
    SoundItem(id: 'calm_6', name: 'Relaxing Guitar', file: 'relaxing_guitar_loop.mp3'),
    SoundItem(id: 'calm_7', name: 'Stene', file: 'stene.mp3'),
    SoundItem(id: 'calm_8', name: 'Soft Alarm', file: 'u_inx5oo5fv3_alarm_327234.mp3'),
    SoundItem(id: 'calm_9', name: 'Chill Lo-Fi', file: 'vibehorn_chill_lofi_hip_hop_482143.mp3'),
  ],
  'Alarm': [
    SoundItem(id: 'alarm_1', name: 'Beeping', file: 'beeping.mp3'),
    SoundItem(id: 'alarm_2', name: 'Microsammy', file: 'microsammy.mp3'),
  ],
  'Fun': [
    SoundItem(id: 'fun_1', name: 'Tilli Lilik', file: 'tilli_lilik.mp3'),
  ],
  'Others': [
    SoundItem(id: 'others_1', name: 'Soundreality Rhythm', file: 'soundreality_rhythm.mp3'),
  ],
};

// Category icons mapping
const Map<String, String> categoryIcons = {
  'Bright':    'wb_sunny',
  'Noisy':     'volume_up',
  'Energetic': 'bolt',
  'Calm':      'coffee',
  'Alarm':     'alarm',
  'Fun':       'sentiment_very_satisfied',
  'Others':    'notifications',
};
