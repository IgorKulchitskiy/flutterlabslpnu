class AlarmConfig {
  final int id;
  final String title;
  final String phone;
  final String arm;
  final String disarm;

  AlarmConfig({
    required this.id,
    required this.title,
    required this.phone,
    required this.arm,
    required this.disarm,
  });

  factory AlarmConfig.fromJson(Map<String, dynamic> json) {
    return AlarmConfig(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      arm: (json['arm'] ?? '').toString(),
      disarm: (json['disarm'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'phone': phone,
      'arm': arm,
      'disarm': disarm,
    };
  }
}
