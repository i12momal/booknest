import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
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

      // Buscar préstamos activos o pendientes para este usuario
      final numberLoans = await BaseService.client.from('Loan').select().eq('currentHolderId', createLoanViewModel.currentHolderId).or('state.eq.Pendiente,state.eq.Aceptado');

      if(numberLoans.length == 3){
        return {
          'success': false,
          'message': 'Ya dispones de tres solicitudes de préstamo Pendientes o Aceptadas.',
        };
      }

      // Buscar préstamos activos o pendientes para este libro
      final existingLoans = await BaseService.client
          .from('Loan')
          .select()
          .eq('bookId', createLoanViewModel.bookId)
          .or('state.eq.Pendiente,state.eq.Aceptado');

      if (existingLoans.isNotEmpty) {
        for (final loan in existingLoans) {
          final existingUserId = loan['currentHolderId'];
          final loanState = loan['state'];
          final existingFormat = loan['format'];

          // Si el préstamo es del mismo usuario, sin importar el formato
          if (existingUserId == createLoanViewModel.currentHolderId) {
            return {
              'success': false,
              'message': 'Ya has solicitado un préstamo para este libro.',
            };
          }

          // Si el préstamo es de otro usuario y en el mismo formato
          if (existingFormat == createLoanViewModel.format) {
            if (loanState == 'Pendiente') {
              return {
                'success': false,
                'message': 'Este libro está pendiente de préstamo a otro usuario en este formato.',
              };
            } else if (loanState == 'Aceptado') {
              return {
                'success': false,
                'message': 'Este libro ya ha sido prestado a otro usuario en este formato.',
              };
            }
          }

          // Otro usuario y otro formato => permitido
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
        'currentPage': createLoanViewModel.currentPage,
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
          
          // Obtener el formato del libro
          final bookResponse = await BaseService.client.from('Book').select('format::text').eq('id', bookId).single();
          
          if (bookResponse != null && bookResponse['format'] != null) {
            final rawFormat = bookResponse['format'];

            List<String> bookFormats = rawFormat.toString().split(',').map((f) => f.trim().toLowerCase()).toList();

            // Extraer los formatos en los que ya está prestado
            List<String> loanFormats = await getLoanedFormats(bookId);
 
            // Verificar cuántos formatos del libro están en préstamo aceptado
            int matchedFormats = bookFormats.where((format) => loanFormats.contains(format)).length;

            // Lógica de disponibilidad
            String newState = 'Disponible';
            if (matchedFormats == bookFormats.length) {
              newState = 'No Disponible';
            }
            
            // Actualizar el estado solo si es No Disponible
            await BaseService.client
                .from('Book')
                .update({'state': newState})
                .eq('id', bookId);
          }
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
            String newState = 'Disponible';
            final resp = await BaseService.client
                .from('Book')
                .update({'state': newState})
                .eq('id', bookId);
          print('responde: $resp');
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



  Future<List<String>> getAvailableFormats(int bookId, List<String> formats) async {
    try {
      // Obtener los préstamos con el estado 'Aceptado' y el 'bookId'
      final loanData = await BaseService.client
          .from('Loan')
          .select('format')
          .eq('bookId', bookId)
          .eq('state', 'Aceptado');

      // Filtramos los formatos prestados
      final loanedFormats = (loanData as List).map((loan) => (loan['format'] as String).trim().toLowerCase()).toSet();

      // Filtramos los formatos disponibles (aquellos que no están prestados)
      final availableFormats = formats.where((f) => !loanedFormats.contains(f)).toList();

      return availableFormats;
    } catch (e) {
      print('Error en getAvailableFormats: $e');
      return [];
    }
  }

  Future<List<String>> getLoanedFormats(int bookId) async {
    try {
      final loanData = await BaseService.client
          .from('Loan')
          .select('format')
          .eq('bookId', bookId)
          .eq('state', 'Aceptado');

      final loanedFormats = (loanData as List)
          .map((loan) => loan['format'])
          .where((f) => f != null)
          .map((f) => f.toString().trim().toLowerCase())
          .toList();

      return loanedFormats;
    } catch (e) {
      print('Error en getLoanedFormats: $e');
      return [];
    }
  }


  Future<List<Map<String, String>>> getLoanedFormatsAndStates(int bookId) async {
    try {
      final loanData = await BaseService.client
          .from('Loan')
          .select('format, state')
          .eq('bookId', bookId)
          .or('state.eq.Aceptado, state.eq.Pendiente');

      final loanedFormats = (loanData as List)
          .where((loan) => loan['format'] != null && loan['state'] != null)
          .map((loan) => {
                'format': loan['format'].toString().trim().toLowerCase(),
                'state': loan['state'].toString().trim()
              })
          .toList();

      return loanedFormats;
    } catch (e) {
      print('Error en getLoanedFormats: $e');
      return [];
    }
  }




  Future<List<Map<String, dynamic>>> getLoansByBookId(int bookId) async {
    try {
      if (BaseService.client == null) return [];

      final response = await BaseService.client
          .from('Loan')
          .select()
          .eq('bookId', bookId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener préstamos de un libro: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> cancelLoan(int bookId, int? notificationId, String? format) async {
    try {
      // Eliminamos la notificación si existe
      if (notificationId != null) {
        await BaseService.client
            .from('Notifications')
            .delete()
            .eq('id', notificationId);
      }

      if (format == null) {
        return {
          'success': false,
          'message': 'Formato no especificado para eliminar la solicitud.'
        };
      }

      // Eliminamos la solicitud de préstamo (solo si está en estado Pendiente)
      final response = await BaseService.client
          .from('Loan')
          .delete()
          .eq('bookId', bookId)
          .eq('state', 'Pendiente')
          .eq('format', format)
          .select();

      // Recalcular el estado del libro si se eliminó algo
      if (response.isNotEmpty) {
        final bookResponse = await BaseService.client
            .from('Book')
            .select('id, format')
            .eq('id', bookId)
            .single();

        if (bookResponse != null) {
          final bookFormats = bookResponse['format']
              .toString()
              .split(',')
              .map((f) => f.trim().toLowerCase())
              .toList();

          final loanedFormats = await LoanController().getLoanedFormatsAndStates(bookId);
          final normalizedLoans = loanedFormats.map((f) => {
                'format': f['format'].toString().trim().toLowerCase(),
                'state': f['state'].toString().trim().toLowerCase(),
              }).toList();

          String newState = 'Disponible';

          if (bookFormats.length == 2) {
            final acceptedCount =
                normalizedLoans.where((f) => f['state'] == 'aceptado').length;
            final pendingCount =
                normalizedLoans.where((f) => f['state'] == 'pendiente').length;

            if ((acceptedCount == 2) ||
                (pendingCount == 2) ||
                (acceptedCount == 1 && pendingCount == 1)) {
              newState = 'No Disponible';
            }
          } else if (bookFormats.length == 1 && normalizedLoans.isNotEmpty) {
            final state = normalizedLoans.first['state'];
            if (state == 'pendiente' || state == 'aceptado') {
              newState = 'Pendiente';
            }
          }

          print('Nuevo estado del libro tras cancelación: $newState');
          await BookController().changeState(bookId, newState);
        }

        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'No se pudo eliminar la solicitud o no existía'
        };
      }
    } catch (e) {
      print('Error al cancelar la solicitud: $e');
      return {'success': false, 'message': 'Error al eliminar la solicitud'};
    }
  }


  // Método que comprueba si el usuario ya ha realizado una solicitud de préstamo para un libro
  Future<Map<String, dynamic>> checkExistingLoanRequest(int bookId, String userId) async {
    try {
      if (BaseService.client == null) {
        return {'exists': false, 'notificationId': null};
      }

      final response = await BaseService.client
          .from('Loan')
          .select()
          .eq('currentHolderId', userId)
          .eq('state', 'Pendiente')
          .eq('bookId', bookId)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return {
          'exists': true,
          'notificationId': response['notificationId'],
          'format': response['format']
        };
      } else {
        return {'exists': false, 'notificationId': null, 'format': null};
      }
    } catch (e) {
      print('Error al obtener solicitud del usuario: $e');
      return {'exists': false, 'notificationId': null, 'format': null};
    }
  }


  Future<bool> getActiveLoanForBookAndFormat(int bookId, String format) async {
    try {
      final response = await BaseService.client
          .from('Loan')
          .select()
          .eq('bookId', bookId)
          .eq('format', format)
          .eq('state', 'Aceptado')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error al verificar préstamo activo: $e');
      return false;
    }
  }

  Future<bool> areAllFormatsAvailable(int bookId, List<String> formats) async {
    try {
      for (final format in formats) {
        final hasActiveLoan = await getActiveLoanForBookAndFormat(bookId, format);
        if (hasActiveLoan) {
          return false; // Al menos un formato sigue prestado
        }
      }
      return true; // Todos los formatos están disponibles
    } catch (e) {
      print('Error al verificar disponibilidad de formatos: $e');
      return false;
    }
  }


}