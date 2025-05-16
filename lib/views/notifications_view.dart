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

  List<String> _extractRelatedBooks(String message) {
    final match = RegExp(r'los siguientes libros físicos como contraprestación: (.+)').firstMatch(message);
    if (match != null) {
      final books = match.group(1)!.split(',').map((b) => b.trim().replaceAll('"', '')).toList();
      return books;
    }
    return [];
  }

  Future<bool?> _showCompensationDialog(Map<String, dynamic> notification, List<String> relatedBooks) async {
    String? selected = notification['compensationSelected'];

    return showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF112363), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Selecciona una contraprestación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...relatedBooks.map((book) => RadioListTile<String>(
                          title: Text(book),
                          value: book,
                          groupValue: selected,
                          onChanged: (value) => setStateDialog(() => selected = value),
                        )),
                    RadioListTile<String>(
                      title: const Text('Fianza'),
                      value: 'Fianza',
                      groupValue: selected,
                      onChanged: (value) => setStateDialog(() => selected = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: selected != null
                      ? () {
                          notification['compensationConfirmed'] = true;
                          notification['compensationSelected'] = selected;
                          Navigator.pop(context, true);
                        }
                      : null,
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
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
          notification['message'] = notification['message'] ?? 'Sin mensaje';
          print('Mensaje cargado: ${notification['message']}');


          notification['compensationSelected'] = loan['compensation'];
          notification['compensationConfirmed'] = loan['compensation'] != null;
          notification['currentHolderId'] = loan['currentHolderId'];


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

 Future<void> _updateLoanState(Map<String, dynamic> loan, String newState, String? selectedCompensation, List<String> relatedBooks) async {
    final loanId = loan['loanId'];
    final currentHolderId = loan['currentHolderId'] as String?;
    final requesterId = loan['currentHolderId']; // El que ha ofrecido los libros para intercambio

    await LoanController().updateLoanState(loanId, newState, compensation: selectedCompensation);

    if (newState == 'Aceptado' && currentHolderId != null && relatedBooks.isNotEmpty) {
      for (final title in relatedBooks) {
        final bookId = await BookController().getBookIdByTitleAndOwner(title, currentHolderId);
        if (bookId == null || bookId == 0) continue;

        final isSelected = selectedCompensation != null && title.trim().toLowerCase() == selectedCompensation.trim().toLowerCase();

        if (selectedCompensation == 'Fianza') {
          // Elimina todos los loans ofrecidos
          await LoanController().deleteLoanByBookAndUser(bookId, requesterId);
          await BookController().changeState(bookId, 'Disponible');
        } else {
          if (isSelected) {
            // ACTUALIZA loan seleccionado: accepted + nuevo currentHolder
            await LoanController().acceptCompensationLoan(bookId: bookId, userId: requesterId, newHolderId: currentHolderId, compensation: loan['bookName']);
            await BookController().changeState(bookId, 'No Disponible');
          } else {
            // Elimina los loans no seleccionados
            await LoanController().deleteLoanByBookAndUser(bookId, requesterId);
            await BookController().changeState(bookId, 'Disponible');
          }
        }
      }
    }

    setState(() {
      loan['state'] = newState;
      loan['compensationSelected'] = selectedCompensation;
      loan['compensationConfirmed'] = (selectedCompensation != null);
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
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Marcar como leídas'),
          content: const Text('¿Deseas marcar estas notificaciones como leídas?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Aceptar')),
          ],
        ),
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

                                // Fila con formato, dropdown y ícono
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Formato: ${loan['format']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                    loan['state'] == 'Pendiente'
                                        ? LoanStateDropdown(
                                            selectedState: loan['state'],
                                            onChanged: (newState) {
                                              final books = _extractRelatedBooks(loan['message'] ?? '');
                                              if (newState != null && newState != loan['state']) {
                                                _updateLoanState(loan, newState, loan['compensationSelected'], books);
                                              }
                                            },
                                            disabledOptions: loan['format'] == 'Físico' && !loan['compensationConfirmed'] ? ['Aceptado'] : [],
                                          )
                                        : Text(
                                            loan['state'],
                                            style: TextStyle(color: _getStateColor(loan['state']), fontWeight: FontWeight.bold),
                                          ),
                                    Icon(
                                      isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                      color: isRead ? Colors.green : Colors.grey,
                                    ),
                                  ],
                                ),

                                // Botón "Libros ofrecidos", debajo del Row
                                if (loan['format'] == 'Físico') ...[
                                  if (loan['state'] == 'Pendiente' || loan['state'] == 'Rechazado')...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed: loan['state'] == 'Pendiente'
                                                ? () async {
                                                    final books = _extractRelatedBooks(loan['message'] ?? '');
                                                    final result = await _showCompensationDialog(loan, books);
                                                    if (result == true) {
                                                      setState(() {});
                                                    }
                                                  }
                                                : null,
                                            icon: Icon(Icons.book,
                                                size: 18,
                                                color: loan['state'] == 'Pendiente'
                                                    ? const Color(0xFF112363)
                                                    : Colors.grey),
                                            label: Text(
                                              'Libros ofrecidos',
                                              style: TextStyle(
                                                decoration: TextDecoration.underline,
                                                color: loan['state'] == 'Pendiente'
                                                    ? const Color(0xFF112363)
                                                    : Colors.grey,
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 0),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              alignment: Alignment.centerLeft,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ]else...[
                                    Text('Contraprestación: ${loan['compensationSelected']}', style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                                  ] 
                                ]
                              ] else if (loan['type'] == 'Préstamo Aceptado' || loan['type'] == 'Préstamo Rechazado' || loan['type'] == 'Préstamo Devuelto') ...[
                                Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      child: Text(
                                        loan['message'] ?? '',
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Icon(
                                        isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                        color: isRead ? Colors.green : Colors.grey,
                                      ),
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