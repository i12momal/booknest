import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/entities/viewmodels/loan_view_model.dart';
import 'package:booknest/services/base_service.dart';

// Servicio con los métodos de negocio para la entidad Préstamo.
class LoanService extends BaseService{

  // Método asíncrono para crear una solicitud de préstamo de un libro
  Future<Map<String, dynamic>> createLoan(CreateLoanViewModel createLoanViewModel) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Buscar préstamos activos o pendientes para este usuario
      if (createLoanViewModel.ownerId != createLoanViewModel.currentHolderId) {
        final userLoans = await BaseService.client.from('Loan').select().eq('currentHolderId', createLoanViewModel.currentHolderId).or('state.eq.Pendiente,state.eq.Aceptado');

        // Filtra solo los préstamos en los que el usuario está solicitando libros de otros (no ofreciendo)
        final externalRequests = userLoans.where((loan) =>
            loan['ownerId'] != createLoanViewModel.currentHolderId).toList();

        if (externalRequests.length >= 3) {
          return {
            'success': false,
            'message':'Ya dispones de tres solicitudes de préstamo Pendientes o Aceptadas.',
          };
        }
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

  // Método asíncrono que obtiene las solicitudes de préstamos pendientes de un usuario.
  Future<List<Map<String, dynamic>>> getUserPendingLoans(String userId) async {
    try {
      if (BaseService.client == null) {
        return [];
      }

      final response = await BaseService.client.from('Loan').select().eq('ownerId', userId).eq('state', 'Pendiente').order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('Error al obtener solicitudes pendientes: $e');
      return [];
    }
  }

  // Método asíncrono que obtiene los datos de una solicitud de préstamo.
  Future<Map<String, dynamic>> getLoanById(int loanId) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Llamada a la base de datos para obtener los datos del préstamo.
      final response = await BaseService.client.from('Loan').select().eq('id', loanId).maybeSingle();

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

  // Método asíncrono para actualizar el estado de un préstamo.
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
            await BaseService.client.from('Book').update({'state': newState}).eq('id', bookId);
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
            final resp = await BaseService.client.from('Book').update({'state': newState}).eq('id', bookId);
          print('responde: $resp');
          }
      }else{
        // Si no es 'Aceptado' ni 'Devuelto', solo se actualiza el estado
        final response = await BaseService.client.from('Loan').update({'state': newState}).eq('id', loanId).select();
      }
    } catch (e) {
      print('Error al cambiar el estado del préstamo: $e');
    }
  }

  // Método asíncrono que obtiene los libros que han sido prestados a un usuario
  Future<List<Map<String, dynamic>>> getLoansByHolder(String userId) async {
    try {
      if (BaseService.client == null) return [];

      final today = DateTime.now().toIso8601String();

      final response = await BaseService.client
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

  // Método asíncrono que obtiene un préstamo por usuario y libro
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

  // Método para actualizar la página actual por la que se está leyendo un libro.
  Future<void> updateCurrentPage(int loanId, int currentPage) async {
    try {
      await BaseService.client.from('Loan').update({
        'currentPage': currentPage,
      }).eq('id', loanId);
    } catch (e) {
      print('Error en LoanService.updateCurrentPage: $e');
    }
  }

  // Método asíncrono para obtener el progreso guardado de una página
  Future<int?> getSavedPageProgress(String userId, int bookId) async {
    try {
      // Llamada al servicio para consultar el progreso guardado
      final response = await BaseService.client
          .from('Loan')
          .select()
          .eq('currentHolderId', userId)
          .eq('bookId', bookId)
          .maybeSingle();

      if (response != null) {
        return response['currentPage'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error en LoanService.getSavedPageProgress: $e');
      return null; // Retorna null si hay un error
    }
  }

  // Método asíncrono para obtener los formatos disponibles de un libro
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

  // Método asíncrono para obtener los formatos prestados de un libro
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

  // Método asíncrono para obtener los formatos pendientes de un libro
  Future<List<String>> getPendingFormats(int bookId) async {
    try {
      final loanData = await BaseService.client
          .from('Loan')
          .select('format')
          .eq('bookId', bookId)
          .eq('state', 'Pendiente');

      final loanedFormats = (loanData as List)
          .map((loan) => loan['format'])
          .where((f) => f != null)
          .map((f) => f.toString().trim().toLowerCase())
          .toList();

      return loanedFormats;
    } catch (e) {
      print('Error en getPendingFormats: $e');
      return [];
    }
  }

  // Método asíncrono para obtener los formatos prestados y su estado
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

  // Método asíncrono para obtener los préstamos de un libro por su id
  Future<List<Map<String, dynamic>>> getLoansByBookId(int bookId) async {
    try {
      if (BaseService.client == null) return [];

      final response = await BaseService.client.from('Loan').select().eq('bookId', bookId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener préstamos de un libro: $e');
      return [];
    }
  }

  // Método asíncrono para eliminar una solicitud de préstamo realizada sobre un libro.
  Future<Map<String, dynamic>> cancelLoan(int bookId, int? notificationId, String? format) async {
    try {
      // 1. Eliminar notificación si existe
      if (notificationId != null) {
        await BaseService.client.from('Notifications').delete().eq('id', notificationId);
      }

      if (format == null) {
        return {
          'success': false,
          'message': 'Formato no especificado para eliminar la solicitud.'
        };
      }

      // 2. Obtener el préstamo principal (Pendiente)
      final mainLoan = await BaseService.client
          .from('Loan')
          .select('id, offeredLoanIds')
          .eq('bookId', bookId)
          .eq('state', 'Pendiente')
          .eq('format', format)
          .maybeSingle();

      if (mainLoan == null) {
        return {
          'success': false,
          'message': 'No se encontró una solicitud pendiente para este libro y formato.'
        };
      }

      final int mainLoanId = mainLoan['id'];
      final String offeredLoanIdsStr = mainLoan['offeredLoanIds'] ?? '';
      final List<int> offeredLoanIds = offeredLoanIdsStr
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .map(int.parse)
          .toList();

      // 3. Eliminar compensaciones (ofertas físicas asociadas)
      for (final offerLoanId in offeredLoanIds) {
        // Obtener info del préstamo ofrecido antes de eliminarlo
        final offeredLoan = await BaseService.client
            .from('Loan')
            .select('bookId')
            .eq('id', offerLoanId)
            .maybeSingle();

        if (offeredLoan != null) {
          final int offeredBookId = offeredLoan['bookId'];

          // Cambiar el estado del libro a Disponible
          await BookController().changeState(offeredBookId, 'Disponible');
        }

        // Eliminar el préstamo de compensación
        await BaseService.client.from('Loan').delete().eq('id', offerLoanId);
      }

      // 4. Eliminar el préstamo principal
      await BaseService.client.from('Loan').delete().eq('id', mainLoanId);

      // 5. Recalcular el estado del libro original
      final bookResponse = await BaseService.client
          .from('Book')
          .select('id, format')
          .eq('id', bookId)
          .maybeSingle();

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
          final acceptedCount = normalizedLoans.where((f) => f['state'] == 'aceptado').length;
          final pendingCount = normalizedLoans.where((f) => f['state'] == 'pendiente').length;

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

        await BookController().changeState(bookId, newState);
      }

      return {'success': true};
    } catch (e) {
      print('Error al cancelar la solicitud: $e');
      return {'success': false, 'message': 'Error al eliminar la solicitud'};
    }
  }

  // Método asíncrono que comprueba si el usuario ya ha realizado una solicitud de préstamo para un libro
  Future<Map<String, dynamic>> checkExistingLoanRequest(int bookId, String userId) async {
    try {
      if (BaseService.client == null) {
        return {'exists': false, 'notificationId': null, 'format': null};
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
        final loanId = response['id'];
        final notificationResponse = await BaseService.client.from('Notifications').select('id').eq('type', 'Préstamo').eq('relatedId', loanId).limit(1).maybeSingle(); 

        return {
          'exists': true,
          'notificationId': notificationResponse != null ? notificationResponse['id'] : null,
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

  // Método asíncrono que obtiene los préstamos activos de un libro según sus formatos.
  Future<bool> getActiveLoanForBookAndFormat(int bookId, String format) async {
    try {
      final response = await BaseService.client
          .from('Loan')
          .select()
          .eq('bookId', bookId)
          .eq('format', format.toLowerCase())
          .filter('state', 'in', '(Aceptado,Pendiente)')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error al verificar préstamo activo: $e');
      return false;
    }
  }

  // Método asíncrono que comprueba si todos los formatos de un libro están disponibles.
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

  // Método asíncrono para actualizar la contraprestación seleccionada en un intercambio físico.
  Future<void> updateCompensation(String? compensation, int loanId) async {
    try {
      if (BaseService.client == null) {
        return;
      }
      
      await BaseService.client
        .from('Loan')
        .update({
          'compensation': compensation,
        })
        .eq('id', loanId)
        .select();
      
    } catch (e) {
      print('Error al cambiar el estado de la contraprestación: $e');
    }
  }

  // Método asíncrono para crear una solicitud de préstamo física.
  Future<Map<String, dynamic>> createLoanOfferPhysicalBook(CreateLoanViewModel createLoanViewModel, int principalLoanId) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
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

      final response = await BaseService.client.from('Loan').insert(loanData).select().single();

      print("Respuesta del servicio Loan: $response");

      // Guardar el id de las compensaciones
      // Obtener el préstamo principal
      final principalLoan = await BaseService.client
          .from('Loan')
          .select('offeredLoanIds')
          .eq('id', principalLoanId)
          .single();

      String currentOfferedLoanIds = (principalLoan['offeredLoanIds'] ?? '').toString();
      List<String> ids = currentOfferedLoanIds.split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final newLoanId = response['id'].toString();
      if (!ids.contains(newLoanId)) {
        ids.add(newLoanId);
      }

      final updatedString = ids.join(',');

      await BaseService.client.from('Loan').update({'offeredLoanIds': updatedString}).eq('id', principalLoanId);

      if (response != null) {
        return {
          'success': true,
          'message': 'Préstamo ofrecido registrado exitosamente',
          'data': response
        };
      } else {
        return {'success': false, 'message': 'Error al registrar el préstamo ofrecido'};
      }
    } catch (ex) {
      return {'success': false, 'message': ex.toString()};
    }
  }

  // Método asíncrono que borra loan por libro y usuario (para los libros no seleccionados o si fue fianza)
  Future<void> deleteLoanByBookAndUser(int bookId, String userId) async {
    try {
      await BaseService.client
          .from('Loan')
          .delete()
          .eq('bookId', bookId)
          .eq('ownerId', userId);
      print(' Loan eliminado: libro $bookId, usuario $userId');
    } catch (e) {
      print(' Error al eliminar loan: $e');
    }
  }

  // Método asíncrono que acepta el libro seleccionado: actualiza estado y currentHolderId
  Future<int?> acceptCompensationLoan({required int bookId, required String userId, required String? newHolderId, required String compensation}) async {
    try {
      print('Valores del acceptCompensationLoan $bookId, $userId, $newHolderId, $compensation');
      final response = await BaseService.client
          .from('Loan')
          .update({
            'state': 'Aceptado',
            'currentHolderId': newHolderId,
            'compensation': compensation,
          })
          .eq('bookId', bookId)
          .eq('ownerId', userId)
          .select('id')
          .maybeSingle();

      if (response != null && response['id'] != null) {
        final loanId = response['id'] as int;
        print('✅ Loan aceptado con id: $loanId');
        return loanId;
      } else {
        print('⚠ No se encontró loan para actualizar.');
        return null;
      }
    } catch (e) {
      print('❌ Error al aceptar loan: $e');
      return null;
    }
  }

  // Método asíncrono que obtiene el estado de una solicitud de préstamo realizada por un usuario.
  Future<String> getLoanStateForUser(int loanId, String userId) async {
    try {
      final response = await BaseService.client
          .from('Loan')
          .select('state')
          .eq('id', loanId)
          .eq('ownerId', userId)
          .maybeSingle();

      if (response != null && response['state'] != null) {
        return response['state'] as String;
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print('Exception fetching loan state: $e');
      return 'Unknown';
    }
  }

  // Método asíncrono que obtiene el id de la solicitud de préstamo de un usuario.
  Future<int?> getActualLoanIdForUserAndBook(int loanId, String userId) async {
    try {
      final response = await BaseService.client
          .from('Loan')
          .select()
          .eq('id', loanId)
          .eq('currentHolderId', userId)
          .maybeSingle();

      if (response == null) return null;

      return response['id'] as int?;
    } catch (e) {
      print('Error al obtener el préstamo actual: $e');
      return null;
    }
  }

  // Método asíncrono para actualizar el estado de una solicitud de préstamo
  Future<void> updateLoanStateByUser(String? userId, int loanId, int compensationLoanId, String newState,) async {
    try {
      if (BaseService.client == null || userId == null) {
        return;
      }

      // Obtener los dos préstamos
      final response = await BaseService.client.from('Loan').select().filter('id', 'in', '($loanId,$compensationLoanId)') as List;

      if (response.isEmpty) {
        return;
      }

      print('Préstamos coincidentes: $response');

      final loans = response.cast<Map<String, dynamic>>();

      // Buscar el préstamo donde ownerId coincida con userId
      final targetLoan = loans.firstWhere(
        (loan) => loan['ownerId'] == userId,
        orElse: () => <String, dynamic>{},
      );

      if (targetLoan.isEmpty) {
        return;
      }

      // Actualizar el estado del préstamo
      await BaseService.client
          .from('Loan')
          .update({
            'state': newState,
          })
          .eq('id', targetLoan['id'])
          .select();

      // Obtener el bookId del préstamo para actualizar el libro correspondiente
      final int bookId = targetLoan['bookId'];

      // Actualizar estado en Book solo para ese bookId
      await BaseService.client
          .from('Book')
          .update({
            'state': 'Disponible',
          })
          .eq('id', bookId)
          .select();

    } catch (e) {
      print('Error al cambiar el estado de la contraprestación: $e');
    }
  }

  // Método asíncrono para crear la solicitud de préstamo asociada cuando la contraprestación seleccionada ha sido Fianza.
  Future<Map<String, dynamic>> createLoanFianza(CreateLoanViewModel createLoanViewModel, String bookTitle) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
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
        'compensation': bookTitle
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
          'message': 'Préstamo ofrecido registrado exitosamente',
          'data': response
        };
      } else {
        return {'success': false, 'message': 'Error al registrar el préstamo ofrecido'};
      }
    } catch (ex) {
      return {'success': false, 'message': ex.toString()};
    }
  }

  // Método para eliminar una solicitud de préstamo
  Future<void> deleteLoan(int loanId) async {
    try {
      // Obtener el id del libro asociado al préstamo
      final response = await BaseService.client
          .from('Loan')
          .select('bookId')
          .eq('id', loanId)
          .limit(1)
          .maybeSingle();

      final bookId = response != null ? response['bookId'] : null;

      // Eliminar préstamo
      await BaseService.client.from('Loan').delete().eq('id', loanId);

      // Si se obtuvo el bookId, actualizar su estado
      if (bookId != null) {
        await BaseService.client.from('Book').update({'state': 'Disponible'}).eq('id', bookId);
      }

    } catch (e) {
      print('Error al eliminar loan: $e');
    }
  }

}