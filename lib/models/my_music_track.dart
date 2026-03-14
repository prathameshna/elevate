class MyMusicTrack {
  final String id;
  final String name;      // display name (filename without extension)
  final String filePath;  // full device path

  const MyMusicTrack({
    required this.id,
    required this.name,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
  };

  factory MyMusicTrack.fromJson(Map<String, dynamic> json) => MyMusicTrack(
    id: json['id'],
    name: json['name'],
    filePath: json['filePath'],
  );
}
