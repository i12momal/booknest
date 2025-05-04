import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/notification_controller.dart';
import 'package:booknest/main.dart';
import 'package:booknest/views/notifications_view.dart';
import 'package:flutter/material.dart';

class Background extends StatefulWidget {
  final Widget child;
  final String title;
  final VoidCallback? onBack;
  final bool showNotificationIcon;
  final bool showRowIcon;
  final bool showExitIcon;

  const Background({
    super.key,
    required this.child,
    required this.title,
    this.onBack,
    this.showNotificationIcon = true,
    this.showRowIcon = true,
    this.showExitIcon = false,
  });

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> {
  late Future<int> _notificationCount;

  @override
  void initState() {
    super.initState();
    _notificationCount = _fetchNotificationCount();
  }

  Future<int> _fetchNotificationCount() async {
    final userId = await AccountController().getCurrentUserId();
    if (userId == null) return 0;

    final response = await NotificationController().getUnreadUserNotifications(userId);
    
    if (mounted) {
      setState(() {
        _notificationCount = Future.value(response.length);
      });
    }

    return response.length;
  }

  void _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AccountController().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyApp()), 
          (route) => false,
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _notificationCount = _fetchNotificationCount();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('showExitIcon: ${widget.showExitIcon}');
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
                  automaticallyImplyLeading: false,
                  title: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: widget.showExitIcon
                    ? IconButton(
                        icon: const Icon(Icons.logout_sharp),
                        color: Colors.white,
                        onPressed: () => _confirmLogout(context),
                      )
                    : (widget.onBack != null && widget.showRowIcon)
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.white,
                            onPressed: () => widget.onBack?.call(),
                          )
                        : null,
                  actions: widget.showNotificationIcon
                      ? [
                          FutureBuilder<int>(
                            future: _notificationCount,
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_none),
                                    color: Colors.white,
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationsView(),
                                        ),
                                      );
                                      setState(() {
                                        _notificationCount = _fetchNotificationCount();
                                      });
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
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
