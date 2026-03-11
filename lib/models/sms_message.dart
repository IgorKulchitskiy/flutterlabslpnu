class SmsMessage {
  final String address;
  final String body;
  final DateTime date;

  SmsMessage({
    required this.address,
    required this.body,
    required this.date,
  });

  factory SmsMessage.fromMap(Map<dynamic, dynamic> map) {
    return SmsMessage(
      address: map['address']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['date']?.toString() ?? '0') ?? 0,
      ),
    );
  }
}
