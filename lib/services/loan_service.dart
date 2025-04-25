import 'package:booknest/entities/viewmodels/loan_view_model.dart';
import 'package:booknest/services/base_service.dart';

// Servicio con los métodos de negocio para la entidad Préstamo.
class LoanService extends BaseService{

  Future<Map<String, dynamic>> createLoan(CreateLoanViewModel createLoanViewModel) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Buscar préstamos activos o pendientes para este libro y formato
      final existingLoans = await BaseService.client
          .from('Loan')
          .select()
          .eq('bookId', createLoanViewModel.bookId)
          .eq('format', createLoanViewModel.format)
          .or('state.eq.Pendiente,state.eq.Aceptado');

      if (existingLoans.isNotEmpty) {
        for (final loan in existingLoans) {
          final existingUserId = loan['currentHolderId'];
          final loanState = loan['state'];

          // Si el préstamo es del mismo usuario
          if (existingUserId == createLoanViewModel.currentHolderId) {
            return {
              'success': false,
              'message': 'Ya has solicitado un préstamo para este libro.',
            };
          }

          // Si otro usuario ya tiene un préstamo pendiente o aceptado
          if (loanState == 'Pendiente') {
            return {
              'success': false,
              'message': 'Este libro está pendiente de préstamo a otro usuario.',
            };
          } else if (loanState == 'Aceptado') {
            return {
              'success': false,
              'message': 'Este libro ya ha sido prestado a otro usuario.',
            };
          }
        }
      }

      // Crear el nuevo préstamo
      final Map<String, dynamic> loanData = {
        'ownerId': createLoanViewModel.ownerId,
        'currentHolderId': createLoanViewModel.currentHolderId,
        'bookId': createLoanViewModel.bookId,
        'startDate': createLoanViewModel.startDate,
        'endDate': createLoanViewModel.endDate,
        'format': createLoanViewModel.format,
        'state': createLoanViewModel.state,
      };

      final response = await BaseService.client
          .from('Loan')
          .insert(loanData)
          .select()
          .single();

      if (response != null) {
        return {
          'success': true,
          'message': 'Préstamo registrado exitosamente',
          'data': response
        };
      } else {
        return {'success': false, 'message': 'Error al registrar el préstamo'};
      }
    } catch (ex) {
      return {'success': false, 'message': ex.toString()};
    }
  }


}