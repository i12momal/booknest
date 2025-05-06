import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/controllers/notification_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/loan_state.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  int currentPage = 1;
  final int notificationsPerPage = 20;
  List<Map<String, dynamic>> allNotifications = [];

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications().then((notifications) {
      allNotifications = notifications;
      return notifications;
    });
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final userId = await AccountController().getCurrentUserId();
    if (userId == null) return [];

    final notifications = await NotificationController().getUserNotifications(userId);

    for (var notification in notifications) {
      if (notification["type"] == 'Préstamo') {
        final loanResponse = await LoanController().getLoanById(notification['relatedId']);
        if (loanResponse['success'] == true && loanResponse['data'] != null) {
          final loan = loanResponse['data'];
          final book = await BookController().getBookById(loan['bookId']);
          final user = await UserController().getUserById(loan['currentHolderId']);
          notification['bookName'] = book?.title ?? 'Desconocido';
          notification['userName'] = user?.name ?? 'Usuario desconocido';
          notification['format'] = loan['format'] ?? 'Desconocido';
          notification['state'] = loan['state'] ?? 'Desconocido';
          notification['loanId'] = loan['id'] ?? 0;
        }
      } 
    }
    return notifications;
  }

  List<Map<String, dynamic>> get paginatedNotifications {
    final start = (currentPage - 1) * notificationsPerPage;
    final end = (start + notificationsPerPage).clamp(0, allNotifications.length);
    if (start >= allNotifications.length) return [];
    return allNotifications.sublist(start, end);
  }

  Future<void> _updateLoanState(Map<String, dynamic> loan, String newState) async {
    final loanId = loan['loanId'];
    await LoanController().updateLoanState(loanId, newState);
    setState(() {
      loan['state'] = newState;
    });
  }

  Future<void> _markAsRead(Map<String, dynamic> loan) async {
    if (!(loan['read'] ?? false)) {
      await NotificationController().markNotificationAsRead(loan['id']);
      setState(() {
        loan['read'] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      title: 'Notificaciones',
      onBack: () => Navigator.pop(context),
      showNotificationIcon: false,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (allNotifications.isEmpty) {
            return const Center(child: Text('No tienes notificaciones.'));
          }

          final loans = paginatedNotifications;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    final isRead = loan['read'] ?? false;

                    return GestureDetector(
                      onTap: () => _markAsRead(loan),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isRead ? Colors.grey.withAlpha((255 * 0.5).toInt()) : const Color(0xFF112363),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isRead
                              ? Colors.grey.withAlpha((255 * 0.2).toInt())
                              : Colors.white,
                        ),
                        child: Opacity(
                          opacity: isRead ? 0.5 : 1.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if(loan['type']=='Préstamo')...[
                                Text(
                                  'Libro: ${loan['bookName']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text('Solicitado por: ${loan['userName']}'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Formato: ${loan['format']}',
                                      style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
                                    ),
                                    loan['state'] == 'Pendiente'
                                        ? LoanStateDropdown(
                                            selectedState: loan['state'],
                                            onChanged: (newState) {
                                              if (newState != null && newState != loan['state']) {
                                                _updateLoanState(loan, newState);
                                              }
                                            },
                                          )
                                        : Text(
                                            loan['state'] ?? 'Formato desconocido',
                                            style: TextStyle(
                                              color: _getStateColor(loan['state'] ?? 'Formato desconocido'),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),            
                                  Icon(
                                    isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                    color: isRead ? Colors.green : Colors.grey,
                                  ),
                                ],
                              ),
                              ]else if(loan['type']=='Préstamo Aceptado')...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    loan['message'], 
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                      color: isRead ? Colors.green : Colors.grey,
                                    ),
                                  ],
                                ),
                              ]else if(loan['type']=='Préstamo Devuelto')...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    loan['message'], 
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                      color: isRead ? Colors.green : Colors.grey,
                                    ),
                                  ],
                                ),
                              ]else if(loan['type']=='Préstamo Rechazado')...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    loan['message'], 
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                      color: isRead ? Colors.green : Colors.grey,
                                    ),
                                  ],
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: currentPage > 1
                          ? () => setState(() => currentPage--)
                          : null,
                    ),
                    Text('Página $currentPage de ${((allNotifications.length) / notificationsPerPage).ceil()}'),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: currentPage * notificationsPerPage < allNotifications.length
                          ? () => setState(() => currentPage++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'rechazado':
        return Colors.red;
      case 'aceptado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
