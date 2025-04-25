import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/views/notifications_view.dart';
import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  final String title;
  final VoidCallback? onBack;
  final bool showNotificationIcon;

  const Background({
    super.key,
    required this.child,
    required this.title,
    this.onBack,
    this.showNotificationIcon = true,
  });

  Future<int> _fetchNotificationCount() async {
    // Simula obtener el ID del usuario
    final userId = await AccountController().getCurrentUserId();
    if (userId == null) return 0;

    // Simula obtener las solicitudes pendientes del usuario
    final response = await LoanController().getPendingLoansForUser(userId);
    return response.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF112363),
            width: 3,
          ),
        ),
        child: Column(
          children: [
            PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF112363), Color(0xFF2140AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.centerRight,
                    stops: [0.42, 0.74],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: AppBar(
                  title: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: onBack != null
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.white,
                          onPressed: onBack,
                        )
                      : null,
                  actions: showNotificationIcon
                      ? [
                          FutureBuilder<int>(
                            future: _fetchNotificationCount(),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_none),
                                    color: Colors.white,
                                    onPressed: () {
                                      // Navega a la pantalla de notificaciones
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationsView(),
                                        ),
                                      );
                                    },
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: 6,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$count',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ]
                      : [],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}