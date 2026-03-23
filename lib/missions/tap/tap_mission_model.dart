class TapMissionConfig {
  final int tapCount;
  final int seconds;

  const TapMissionConfig({
    this.tapCount = 50,
    this.seconds = 10,
  });

  Map<String, dynamic> toJson() => {
    'tapCount': tapCount,
    'seconds': seconds,
  };

  factory TapMissionConfig.fromJson(Map<String, dynamic> json) =>
      TapMissionConfig(
        tapCount: json['tapCount'] as int? ?? 50,
        seconds: json['seconds'] as int? ?? 10,
      );
}
