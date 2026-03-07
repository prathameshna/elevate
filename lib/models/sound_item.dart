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
    SoundItem(id: 'bright_chime',     name: 'Morning Chime',   file: 'bright_chime.mp3'),
    SoundItem(id: 'bright_xylophone', name: 'Xylophone Wake',  file: 'bright_xylophone.mp3'),
    SoundItem(id: 'bright_piano',     name: 'Gentle Piano',    file: 'bright_piano.mp3'),
    SoundItem(id: 'bright_crystal',   name: 'Crystal Bell',    file: 'bright_crystal.mp3'),
    SoundItem(id: 'bright_marimba',   name: 'Sunrise Marimba', file: 'bright_marimba.mp3'),
  ],
  'Noisy': [
    SoundItem(id: 'noisy_buzzer',      name: 'Loud Alarm Tone',  file: 'noisy_buzzer.mp3'),
    SoundItem(id: 'noisy_siren',       name: 'Emergency Siren',  file: 'noisy_siren.mp3'),
    SoundItem(id: 'noisy_beep',        name: 'Digital Beep',     file: 'noisy_beep.mp3'),
    SoundItem(id: 'noisy_airhorn',     name: 'Air Horn',         file: 'noisy_airhorn.mp3'),
    SoundItem(id: 'noisy_school_bell', name: 'School Bell',      file: 'noisy_school_bell.mp3'),
  ],
  'Energetic': [
    SoundItem(id: 'energy_electronic', name: 'Electronic Rise', file: 'energy_electronic.mp3'),
    SoundItem(id: 'energy_drums',      name: 'Power Drums',     file: 'energy_drums.mp3'),
    SoundItem(id: 'energy_fanfare',    name: 'Classic Voice',   file: 'energy_fanfare.mp3'),
    SoundItem(id: 'energy_powerup',    name: 'Power Up',        file: 'energy_powerup.mp3'),
    SoundItem(id: 'energy_cheerful',   name: 'Cheerful',        file: 'energy_action.mp3'),
  ],
  'Calm': [
    SoundItem(id: 'calm_birds',   name: 'Morning Birds',  file: 'other_birds.mp3'),
    SoundItem(id: 'calm_zen',     name: 'Zen Bowl',       file: 'other_zen.mp3'),
    SoundItem(id: 'calm_ocean',   name: 'Ocean Waves',    file: 'other_ocean.mp3'),
    SoundItem(id: 'calm_rain',    name: 'Rain Drops',     file: 'other_rain.mp3'),
    SoundItem(id: 'calm_forest',  name: 'Forest Morning', file: 'other_forest.mp3'),
  ],
  'Alarm': [
    SoundItem(id: 'alarm_classic', name: 'Classic Alarm',    file: 'noisy_beep.mp3'),
    SoundItem(id: 'alarm_digital', name: 'Digital Alarm',    file: 'energy_electronic.mp3'),
    SoundItem(id: 'alarm_retro',   name: 'Retro Alarm',      file: 'fun_retro.mp3'),
    SoundItem(id: 'alarm_loud',    name: 'Loud Alarm Tone',  file: 'noisy_buzzer.mp3'),
  ],
  'Fun': [
    SoundItem(id: 'fun_cartoon',   name: 'Cartoon Alarm', file: 'fun_cartoon.mp3'),
    SoundItem(id: 'fun_rooster',   name: 'Rooster',       file: 'fun_rooster.mp3'),
    SoundItem(id: 'fun_videogame', name: 'Video Game',    file: 'fun_videogame.mp3'),
    SoundItem(id: 'fun_duck',      name: 'Duck Quack',    file: 'fun_duck.mp3'),
    SoundItem(id: 'fun_retro',     name: 'Retro 8-Bit',   file: 'fun_retro.mp3'),
  ],
  'Others': [
    SoundItem(id: 'others_bell',   name: 'Meditation Bell', file: 'other_zen.mp3'),
    SoundItem(id: 'others_nature', name: 'Nature Wake',     file: 'other_forest.mp3'),
    SoundItem(id: 'others_chime',  name: 'Crystal Chime',   file: 'bright_crystal.mp3'),
    SoundItem(id: 'others_upbeat', name: 'Upbeat Rise',     file: 'energy_electronic.mp3'),
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
