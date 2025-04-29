import 'package:booknest/entities/viewmodels/loan_view_model.dart';
import 'package:booknest/services/base_service.dart';

// Servicio con los métodos de negocio para la entidad Préstamo.
class LoanService extends BaseService{

  // Método asíncrono para solicitar el préstamo de un libro
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

      print("Respuesta del servicio Loan: $response");

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

  // Método asíncrono que obtiene las solicitudes de préstamos pendientes.
  Future<List<Map<String, dynamic>>> getUserPendingLoans(String userId) async {
    try {
      if (BaseService.client == null) {
        return [];
      }

      final response = await BaseService.client
          .from('Loan')
          .select()
          .eq('ownerId', userId)
          .eq('state', 'Pendiente').order('created_at', ascending: false);;

      return response;
    } catch (e) {
      print('Error al obtener solicitudes pendientes: $e');
      return [];
    }
  }

  // Método asíncrono que obtiene los datos de un libro.
  Future<Map<String, dynamic>> getLoanById(int loanId) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Llamada a la base de datos para obtener los datos del préstamo.
      final response = await BaseService.client
          .from('Loan')
          .select()
          .eq('id', loanId)
          .maybeSingle();

      print("Respuesta de Supabase: $response");

      // Verificamos si la respuesta contiene datos.
      if (response != null && response.isNotEmpty) {
        return {'success': true, 'message': 'Préstamo obtenido correctamente', 'data': response};
      } else {
        return {'success': false, 'message': 'No se ha encontrado el préstamo'};
      }
    } catch (ex) {
      // Si ocurre alguna excepción, devolverla.
      return {'success': false, 'message': ex.toString()};
    }
  }

  Future<void> updateLoanState(int loanId, String newState) async {
    try {
      if (BaseService.client == null) {
        return;
      }

      // Si el estado es 'Aceptado', se actualiza startDate y endDate
      if (newState == 'Aceptado') {
        final startDate = DateTime.now();
        final endDate = startDate.add(const Duration(days: 30));

        final response = await BaseService.client
            .from('Loan')
            .update({
              'state': newState,
              'startDate': startDate.toIso8601String(),
              'endDate': endDate.toIso8601String(),
            })
            .eq('id', loanId)
            .select();

        print("Estado actualizado a 'Aceptado', startDate: $startDate, endDate: $endDate");

        // Actualizamos también el estado del libro en Book
        if (response != null && response.isNotEmpty) {
          int bookId = response.first['bookId'];
          await BaseService.client
              .from('Book')
              .update({'state': 'No Disponible'})
              .eq('id', bookId);
        }

      // Si el estado es 'Devuelto', se actualiza endDate
      } else if(newState == 'Devuelto'){
          final endDate = DateTime.now();

          final response = await BaseService.client
              .from('Loan')
              .update({
                'state': newState,
                'endDate': endDate.toIso8601String(),
              })
              .eq('id', loanId)
              .select();

          print("Estado actualizado a 'Devuelto', endDate: $endDate");

          // Actualizamos también el estado del libro en Book
          if (response != null && response.isNotEmpty) {
            int bookId = response.first['bookId'];
            await BaseService.client
                .from('Book')
                .update({'state': 'Disponible'})
                .eq('id', bookId);
          }
      }else{
        // Si no es 'Aceptado' ni 'Devuelto', solo se actualiza el estado
        final response = await BaseService.client
            .from('Loan')
            .update({'state': newState})
            .eq('id', loanId)
            .select();
      }
    } catch (e) {
      print('Error al cambiar el estado del préstamo: $e');
    }
  }

  // Método que obtiene los libros que han sido prestados a un usuario
  Future<List<Map<String, dynamic>>> getLoansByHolder(String userId) async {
    try {
      if (BaseService.client == null) return [];

      final today = DateTime.now().toIso8601String();

      final response = await BaseService.client!
          .from('Loan')
          .select()
          .eq('currentHolderId', userId)
          .eq('state', 'Aceptado')
          .lte('startDate', today)
          .gte('endDate', today);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener préstamos activos: $e');
      return [];
    }
  }


  Future<Map<String, dynamic>?> getLoanByUserAndBook(String userId, int bookId) async {
    try {
      final today = DateTime.now().toIso8601String();
      final response = await BaseService.client
          .from('Loan')
          .select()
          .eq('currentHolderId', userId)
          .eq('state', 'Aceptado')
          .eq('bookId', bookId)
          .lte('startDate', today)
          .gte('endDate', today)
          .maybeSingle();

      print('userId: $userId');
      print('response: $response');
      return response;
    } catch (e) {
      print('Error en LoanService.getLoanByUserAndBook: $e');
      return null;
    }
  }

  Future<void> updateCurrentPage(int loanId, int currentPage) async {
    try {
      await BaseService.client.from('Loan').update({
        'currentPage': currentPage,
      }).eq('id', loanId);
    } catch (e) {
      print('Error en LoanService.updateCurrentPage: $e');
    }
  }

  // Método para obtener el progreso guardado de una página
  Future<int?> getSavedPageProgress(String userId, int bookId) async {
    try {
      // Llamada al servicio para consultar el progreso guardado
      final response = await BaseService.client
          .from('Loan') // Asumiendo que la tabla es 'Loan'
          .select() // Seleccionar los campos
          .eq('currentHolderId', userId) // Filtrar por userId
          .eq('bookId', bookId) // Filtrar por bookId
          .maybeSingle(); // Tomar un solo registro (si existe)

      if (response != null) {
        // Si se encuentra el progreso guardado, se asume que la respuesta tiene el campo 'currentPage'
        return response['currentPage'];
      } else {
        return null; // No se encontró progreso guardado
      }
    } catch (e) {
      print('Error en LoanService.getSavedPageProgress: $e');
      return null; // Retorna null si hay un error
    }
  }
  
}