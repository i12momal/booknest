import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/models/loan_chat_model.dart';

// Controlador con los métodos de las acciones de Chats
class LoanChatController extends BaseController{

  // Método para crear un chat de intercambio físico entre dos usuarios.
  Future<int> createChatIfNotExists(int loanId, String ownerId, String requesterId, int? compensationLoanId) async {
    final response =  await loanChatService.createChatIfNotExists(loanId, ownerId, requesterId, compensationLoanId);

    return response;
  }

  // Método para obtener los chats de intercambio físico de un usuario.
  Future<List<LoanChat>> getUserLoanChats(String userId, bool archived) async {
    return await loanChatService.getUserLoanChats(userId, archived);
  }

  // Método que maneja la acción de archivar/desarchivar un chat.
  Future<void> toggleArchiveStatus(int chatId, String userId, bool archive) async {
    await loanChatService.toggleArchiveStatus(chatId, userId, archive);
  }

}