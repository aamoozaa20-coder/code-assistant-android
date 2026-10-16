class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final String? modelName;

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.modelName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'modelName': modelName,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        role: json['role'],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
        modelName: json['modelName'],
      );
}
