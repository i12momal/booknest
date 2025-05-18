class ChatMessage {
  final int id;
  final String userId;
  final int chatId;
  final bool read;
  final String content;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.chatId,
    required this.read,
    required this.content
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      userId: json['userId'],
      chatId: json['chatId'],
      read: json['read'] ?? false,
      content: json['content'] ?? '',
    );
  }
}