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

  bool isSelectionMode = false;
  Set<int> selectedNotificationIds = {};

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
    return allNotifications.sublist(start, end);
  }

  Future<void> _updateLoanState(Map<String, dynamic> loan, String newState) async {
    final loanId = loan['loanId'];
    await LoanController().updateLoanState(loanId, newState);
    setState(() {
      loan['state'] = newState;
    });
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (!(notification['read'] ?? false)) {
      await NotificationController().markNotificationAsRead(notification['id']);
      setState(() {
        notification['read'] = true;
      });
    }
  }

  Future<void> _confirmMarkAsRead() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Marcar como leídas'),
        content: const Text('¿Deseas marcar estas notificaciones como leídas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aceptar')),
        ],
      ),
    );

    if (confirm == true) {
      for (var id in selectedNotificationIds) {
        final notification = allNotifications.firstWhere((n) => n['id'] == id);
        await NotificationController().markNotificationAsRead(id);
        setState(() {
          notification['read'] = true;
        });
      }
      setState(() {
        isSelectionMode = false;
        selectedNotificationIds.clear();
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar notificaciones'),
        content: const Text('¿Deseas eliminar las notificaciones seleccionadas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      final removableNotifications = selectedNotificationIds
          .map((id) => allNotifications.firstWhere((n) => n['id'] == id))
          .where((notification) =>
              notification['type'] != 'Préstamo' ||
              (notification['state'] != 'Pendiente' && notification['state'] != 'Aceptado'))
          .toList();

      for (var notification in removableNotifications) {
        await NotificationController().deleteNotification(notification['id']);
      }

      setState(() {
        allNotifications.removeWhere((n) => removableNotifications.any((r) => r['id'] == n['id']));
        selectedNotificationIds.clear();
        isSelectionMode = false;
      });
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
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      title: isSelectionMode
          ? '${selectedNotificationIds.length} seleccionadas'
          : 'Notificaciones',
      onBack: () {
        if (isSelectionMode) {
          setState(() {
            selectedNotificationIds.clear();
            isSelectionMode = false;
          });
        } else {
          Navigator.pop(context);
        }
      },
      showRowIcon: true,
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
              // Opciones de selección arriba
              if (isSelectionMode) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: paginatedNotifications.every((n) => selectedNotificationIds.contains(n['id'])),
                            onChanged: (value) {
                              setState(() {
                                final idsOnPage = paginatedNotifications.map((n) => n['id'] as int).toSet();

                                final allSelected = idsOnPage.every((id) => selectedNotificationIds.contains(id));

                                if (allSelected) {
                                  selectedNotificationIds.removeAll(idsOnPage);
                                  if (selectedNotificationIds.isEmpty) isSelectionMode = false;
                                } else {
                                  selectedNotificationIds.addAll(idsOnPage);
                                  isSelectionMode = true;
                                }
                              });
                            },

                          ),
                          const Text('Seleccionar todo', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Marcar como leídas',
                            icon: const Icon(Icons.mark_email_read, color: Colors.blue),
                            onPressed: _confirmMarkAsRead,
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _confirmDelete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Lista de notificaciones
              Expanded(
                child: ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    final isRead = loan['read'] ?? false;
                    final isSelected = selectedNotificationIds.contains(loan['id']);

                    return GestureDetector(
                      onTap: () {
                        if (isSelectionMode) {
                          setState(() {
                            isSelected
                                ? selectedNotificationIds.remove(loan['id'])
                                : selectedNotificationIds.add(loan['id']);
                            if (selectedNotificationIds.isEmpty) isSelectionMode = false;
                          });
                        } else {
                          _markAsRead(loan);
                        }
                      },
                      onLongPress: () {
                        setState(() {
                          isSelectionMode = true;
                          selectedNotificationIds.add(loan['id']);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isRead ? Colors.grey.withAlpha(100) : const Color(0xFF112363),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? Colors.blue.withOpacity(0.3)
                              : isRead
                                  ? Colors.grey.withAlpha(50)
                                  : Colors.white,
                        ),
                        child: Opacity(
                          opacity: isRead ? 0.5 : 1.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (loan['type'] == 'Préstamo') ...[
                                Text('Libro: ${loan['bookName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Solicitado por: ${loan['userName']}'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Formato: ${loan['format']}', style: const TextStyle(fontStyle: FontStyle.italic)),
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
                                            loan['state'],
                                            style: TextStyle(color: _getStateColor(loan['state']), fontWeight: FontWeight.bold),
                                          ),
                                    Icon(isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                        color: isRead ? Colors.green : Colors.grey),
                                  ],
                                ),
                              ] else ...[
                                Text(loan['message'], style: const TextStyle(fontSize: 14)),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Icon(isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                      color: isRead ? Colors.green : Colors.grey),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Paginador
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
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
}