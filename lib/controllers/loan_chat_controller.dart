import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/models/loan_chat_model.dart';

class LoanChatController extends BaseController{

  Future<int> createChatIfNotExists(int loanId, String ownerId, String requesterId, int? compensationLoanId) async {
    final response =  await loanChatService.createChatIfNotExists(loanId, ownerId, requesterId, compensationLoanId);

    return response;
  }

  Future<List<LoanChat>> getUserLoanChats(String userId, bool archived) async {
    return await loanChatService.getUserLoanChats(userId, archived);
  }

  Future<void> toggleArchiveStatus(int chatId, String userId, bool archive) async {
    await loanChatService.toggleArchiveStatus(chatId, userId, archive);
  }

}