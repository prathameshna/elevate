class Mission {
  final String id;
  final String name;
  final String description;
  final Set<int> selectedDays;
  final bool enableWakeUpCheck;
  final int completedSlots;
  final int maxSlots;

  Mission({
    required this.id,
    required this.name,
    required this.description,
    required this.selectedDays,
    this.enableWakeUpCheck = false,
    this.completedSlots = 0,
    this.maxSlots = 5,
  });

  Mission copyWith({
    String? id,
    String? name,
    String? description,
    Set<int>? selectedDays,
    bool? enableWakeUpCheck,
    int? completedSlots,
    int? maxSlots,
  }) {
    return Mission(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      selectedDays: selectedDays ?? this.selectedDays,
      enableWakeUpCheck: enableWakeUpCheck ?? this.enableWakeUpCheck,
      completedSlots: completedSlots ?? this.completedSlots,
      maxSlots: maxSlots ?? this.maxSlots,
    );
  }
}
