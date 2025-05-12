import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/views/login_view.dart';
import 'package:flutter/material.dart';

class Footer extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const Footer({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  String? _userImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserImage();
  }

  Future<void> _loadUserImage() async {
    try {
      final userId = await AccountController().getCurrentUserId();
      final user = await UserController().getCurrentUserById(userId);
      if (user != null && user.image != null && user.image!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userImageUrl = user.image!;
          });
        }
      }
    } catch (e) {
      print("Error al obtener imagen del usuario: $e");
    }
  }

  // Función para mostrar el popup de confirmación para cerrar sesión
  void _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar la sesión de tu cuenta?'),
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
          MaterialPageRoute(builder: (context) => const LoginView()), 
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF112363), Color(0xFF2140AF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        currentIndex: widget.selectedIndex,
        onTap: widget.onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_search),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onLongPress: () {
                _confirmLogout(context);
              },
              child: CircleAvatar(
                radius: 12,
                backgroundImage: _userImageUrl != null && _userImageUrl!.isNotEmpty
                    ? NetworkImage(_userImageUrl!)
                    : const AssetImage('assets/images/default.png') as ImageProvider,
                backgroundColor: Colors.transparent,
              ),
            ),
            label: '',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
