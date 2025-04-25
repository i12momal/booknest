import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/widgets/background.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Background(
      title: 'Notificaciones',
      showNotificationIcon: false,
      child: FutureBuilder<List<Map<String, dynamic>>>(  
        future: AccountController().getCurrentUserId().then(
          (userId) => userId != null
              ? LoanController().getPendingLoansForUser(userId)
              : Future.value([]),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final loans = snapshot.data ?? [];

          if (loans.isEmpty) {
            return const Center(child: Text('No tienes notificaciones.'));
          }

          return ListView.builder(
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];

              // Obtener el nombre del libro y el nombre del usuario
              final bookId = loan['bookId'];
              final userId = loan['ownerId'];
              final state = loan['state'];

              // Aquí obtenemos el nombre del libro
              Future<String> getBookName(int bookId) async {
                final book = await BookController().getBookById(bookId);
                return book?.title ?? 'Desconocido';
              }

              // Y aquí obtenemos el nombre del usuario que solicitó el préstamo
              Future<String> getUserName(String userId) async {
                final user = await UserController().getUserById(userId);
                return user?.name ?? 'Usuario desconocido';
              }

              return FutureBuilder<Map<String, String>>(
                future: Future.wait([
                  getBookName(int.tryParse(bookId.toString()) ?? 0),
                  getUserName(userId),
                ]).then((values) => {
                      'bookName': values[0],
                      'userName': values[1],
                    }),
                builder: (context, userBookSnapshot) {
                  if (userBookSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookName = userBookSnapshot.data?['bookName'] ?? 'Desconocido';
                  final userName = userBookSnapshot.data?['userName'] ?? 'Desconocido';

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF112363), width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Libro: $bookName',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Solicitado por: $userName'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Formato: ${loan['format']}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$state',
                              style: TextStyle(
                                color: _getStateColor(state),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  );
                },
              );

            },
          );
        },
      ),
    );
  }
}


Color _getStateColor(String state) {
  switch (state.toLowerCase()) {
    case 'pendiente':
      return Colors.orange;
    case 'rechazado':
      return Colors.red;
    case 'aceptado':
      return Colors.green;
    case 'devuelto':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}
