import 'package:booknest/entities/models/loan_chat_model.dart';
import 'package:booknest/services/base_service.dart';

class LoanChatService extends BaseService {

  Future<int> createChatIfNotExists(int loanId, String ownerId, String requesterId, int? compensationLoanId) async {
    final existing = await BaseService.client.from('LoanChat').select('id').eq('loanId', loanId).maybeSingle();

    if (existing != null) {
      print('Ya existe una conversación para el préstamo $loanId');
      return existing['id'] as int;
    }

    final response = await BaseService.client
        .from('LoanChat')
        .insert({
          'loanId': loanId,
          'loanCompensationId': compensationLoanId,
          'user_1': ownerId,
          'user_2': requesterId,
          'archivedByOwner': false,
          'archivedByHolder': false,
          'deleteByHolder': false,
          'deleteByOwner': false,
        })
        .select('id')
        .single();

    print('Conversación creada para el préstamo $loanId: $response');

    return response['id'] as int;
  }



  

  Future<List<LoanChat>> getUserLoanChats(String userId, bool archived) async {
    final response = await BaseService.client.from('LoanChat').select().then((data) => data as List<dynamic>);

    final chats = response
      .where((chat) {
        final isUser1 = chat['user_1'] == userId;
        final isUser2 = chat['user_2'] == userId;

        if (!(isUser1 || isUser2)) return false;

        return archived
            ? (isUser1 && chat['archivedByOwner'] == true) || (isUser2 && chat['archivedByHolder'] == true)
            : (isUser1 && chat['archivedByOwner'] == false) || (isUser2 && chat['archivedByHolder'] == false);
      })
      .map((chat) => LoanChat.fromJson(chat))
      .toList();

    return chats;
  }



  Future<void> toggleArchiveStatus(int chatId, String userId, bool archive) async {
    try {
      final response = await BaseService.client
          .from('LoanChat')
          .select()
          .eq('id', chatId)
          .single();

      final chat = LoanChat.fromJson(response);

      final isOwner = chat.user_1 == userId;
      if (!isOwner && chat.user_2 != userId) {
        throw Exception('El usuario no pertenece a esta conversación.');
      }

      final columnToUpdate = isOwner ? 'archivedByOwner' : 'archivedByHolder';

      final updateResponse = await BaseService.client
          .from('LoanChat')
          .update({columnToUpdate: archive})
          .eq('id', chatId)
          .select();

      if (updateResponse == null || updateResponse.isEmpty) {
        throw Exception('Error al actualizar el chat: respuesta vacía');
      }

      print('Actualizado $columnToUpdate a $archive en chat $chatId');

    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Problema de red: verifica tu conexión a internet.');
      }
      throw Exception('Error actualizando chat: $e');
    }
  }

}