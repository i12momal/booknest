import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
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
        setState(() {
          _userImageUrl = user.image!;
        });
      }
    } catch (e) {
      print("Error al obtener imagen del usuario: $e");
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
            icon: CircleAvatar(
              radius: 12,
              backgroundImage: _userImageUrl != null && _userImageUrl!.isNotEmpty
                  ? NetworkImage(_userImageUrl!)
                  : const AssetImage('assets/images/default.png') as ImageProvider,
              backgroundColor: Colors.transparent,
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
