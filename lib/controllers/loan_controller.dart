import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/viewmodels/loan_view_model.dart';

class LoanController extends BaseController{

  Future<Map<String, dynamic>> requestLoan(Book book, String format) async {

    // Obtener el ID del usuario que ha solicitado el préstamo
    final userId = await accountService.getCurrentUserId();
    if (userId == null) {
      return {'success': false, 'message': 'Usuario no autenticado'};
    }

    final DateTime startDate = DateTime.now();
    final DateTime endDate = startDate.add(const Duration(days: 30));

    // Creación del viewModel
    final createLoanViewModel = CreateLoanViewModel(
      ownerId: book.ownerId,
      currentHolderId: userId,
      bookId: book.id,
      startDate: startDate.toIso8601String(),
      endDate: endDate.toIso8601String(),
      format: format,
      state: "Pendiente",
    );
    
    // Llamada al servicio para registrar al usuario
    return await loanService.createLoan(createLoanViewModel);
  }


}