class TypingMissionConfig {
  final int taskCount;

  const TypingMissionConfig({
    this.taskCount = 3,
  });

  Map<String, dynamic> toJson() => {
    'taskCount': taskCount,
  };

  factory TypingMissionConfig.fromJson(Map<String, dynamic> json) =>
      TypingMissionConfig(
        taskCount: json['taskCount'] as int? ?? 3,
      );

  static const List<String> kSentences = [
    "Wake Up Right Now",
    "Good Morning Be Ready",
    "Rise and Shine Today",
    "Start Your Day Well",
    "Time To Move On",
    "Hello New Day Here",
    "Fresh Start For You",
    "Make It Count Now",
    "No More Sleeping Today",
    "Get Up And Go",
    "Sun Is Rising High",
    "Day Is Starting Fast",
    "Ready Set Go Time",
    "Focus On Your Goal",
    "Energy Is Flowing Now",
    "Be Brave And Strong",
    "Work Hard Play Hard",
    "Stay Sharp Keep Moving",
    "A New Chance Today",
    "Believe In Your Self",
    "Never Give Up Ever",
    "Dreams Come True Fast",
    "Make Today Great Day",
    "Smile And Be Happy",
    "Peace And Love Always",
    "Keep Calm And Carry",
    "Success Is Near Now",
    "Go For It Today",
    "Be The Best Version",
    "Your Time Is Now"
  ];
}
