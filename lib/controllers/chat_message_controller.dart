import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/models/chat_message_model.dart';
import 'package:booknest/entities/viewmodels/chat_message_view_model.dart';

class ChatMessageController extends BaseController{

  Future<Map<String, dynamic>> createChatMessage(String userId, int chatId, String message) async {
    // Creación del viewModel
    final addChatMessageViewModel = CreateChatMessageViewModel(
      userId: userId,
      chatId: chatId,
      content: message,
      read: false
    );

    // Verificar el contenido del viewModel
    print("Creando mensaje en el chat con los siguientes datos:");
    print("userId: $userId, chatId: $chatId, message: $message");
    
    // Llamada al servicio para registrar al usuario
    return await chatMessageService.createChatMessage(addChatMessageViewModel);
  }


  Future<List<ChatMessage>> getMessagesForChat(int chatId, String userId) async {
    return await chatMessageService.getMessagesForChat(chatId, userId);
  }

  Future<void> markMessageAsRead(int chatId, String userId) async {
    await chatMessageService.markMessageAsRead(chatId, userId);
  }

}