import 'package:booknest/entities/models/chat_message_model.dart';
import 'package:booknest/entities/viewmodels/chat_message_view_model.dart';
import 'package:booknest/services/base_service.dart';

class ChatMessageService extends BaseService{

   Future<Map<String, dynamic>> createChatMessage(CreateChatMessageViewModel createChatMessageViewModel) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Crear el registro en la tabla ChatMessage 
      print("Creando registro en la tabla ChatMessage...");
      final Map<String, dynamic> chatMessageData = {
        'userId': createChatMessageViewModel.userId,
        'chatId': createChatMessageViewModel.chatId,
        'content': createChatMessageViewModel.content,
        'read': createChatMessageViewModel.read
      };
      print("Datos a insertar: $chatMessageData");

      final response = await BaseService.client.from('ChatMessage').insert(chatMessageData).select().single();

      print("Respuesta de la inserción en ChatMessage: $response");

      if (response != null) {
        print("ChatMessage registrado exitosamente");

        return {
          'success': true,
          'message': 'Mensaje registrado en el chat exitosamente',
          'data': response
        };
      } else {
        print("Error: No se pudo crear el registro en la tabla ChatMessage");
        return {'success': false, 'message': 'Error al registrar el mensaje en el chat'};
      }
    } catch (ex) {
      print("Error en createChatMessage: $ex");
      return {'success': false, 'message': ex.toString()};
    }
  }


  Future<List<ChatMessage>> getMessagesForChat(int chatId, String userId) async {
    final response = await BaseService.client
      .from('ChatMessage')
      .select()
      .eq('chatId', chatId)
      .eq('userId', userId)
      .order('id', ascending: false);

    return (response as List).map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<void> markMessageAsRead(int chatId, String userId) async {
    try {
      await BaseService.client
        .from('ChatMessage')
        .update({'read' : true})
        .eq('chatId', chatId).eq('userId', userId)
        .select();

    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Problema de red: verifica tu conexión a internet.');
      }
      throw Exception('Error actualizando chat: $e');
    }
  }


}