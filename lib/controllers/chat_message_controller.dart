import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/models/chat_message_model.dart';
import 'package:booknest/entities/viewmodels/chat_message_view_model.dart';

// Controlador con los métodos de las acciones del Mensaje de un Chat.
class ChatMessageController extends BaseController{

  // Método asíncrono que crea un mensaje en un chat.
  Future<Map<String, dynamic>> createChatMessage(String userId, int chatId, String message) async {
    // Creación del viewModel
    final addChatMessageViewModel = CreateChatMessageViewModel(
      userId: userId,
      chatId: chatId,
      content: message,
      read: false
    );
    
    // Llamada al servicio para registrar el mensaje
    return await chatMessageService.createChatMessage(addChatMessageViewModel);
  }

  // Método asíncrono que obtiene los mensajes de un chat.
  Future<List<ChatMessage>> getMessagesForChat(int chatId, String userId) async {
    return await chatMessageService.getMessagesForChat(chatId, userId);
  }

  // Método asíncrono que marca un mensaje como leído.
  Future<void> markMessageAsRead(int chatId, String userId) async {
    await chatMessageService.markMessageAsRead(chatId, userId);
  }

  // Método asíncrono que borra un mensaje/chat.
  Future<void> deleteMessagesByUser(int chatId, String userId) async {
    await chatMessageService.deleteMessagesByUser(chatId, userId);
  }

  // Método asíncrono que actualiza el estado de un chat del usuario si lo borra.
  Future<void> updateDeleteLoanChat(int chatId, String userId) async {
    await chatMessageService.updateDeleteLoanChat(chatId, userId);
  }

}