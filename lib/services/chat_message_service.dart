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

  Future<Map<String, dynamic>> deleteMessagesByUser(int chatId, String userId) async {
    try {
      final response = await BaseService.client
          .from('ChatMessage')
          .delete()
          .eq('chatId', chatId)
          .eq('userId', userId)
          .select();

      if (response != null && response.isNotEmpty) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'Mensaje no encontrado o no se pudo eliminar'
        };
      }

    } catch (e) {
      return {
        'success': false,
        'message': 'Error al eliminar el mensaje: $e'
      };
    }
  }


  Future<Map<String, dynamic>> updateDeleteLoanChat(int chatId, String userId) async {
    try {
      final response = await BaseService.client
          .from('LoanChat')
          .select()
          .eq('id', chatId)
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'message': 'Chat no encontrado',
        };
      }

      if (response['user_1'] == userId) {
        await BaseService.client
            .from('LoanChat')
            .update({'deleteByHolder': true})
            .eq('id', chatId);
      } else if (response['user_2'] == userId) {
        await BaseService.client
            .from('LoanChat')
            .update({'deleteByOwner': true})
            .eq('id', chatId);
      }

      return {
        'success': true,
        'message': 'Chat actualizado correctamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al eliminar el mensaje: $e',
      };
    }
  }


}