// Modelo de vista del formulario de creación.
class CreateChatMessageViewModel {
  final String userId;
  final int chatId;
  final bool read;
  final String content;

  CreateChatMessageViewModel({
    required this.userId,
    required this.chatId,
    required this.read,
    required this.content
  });
}