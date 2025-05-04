import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/user_profile_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/footer.dart';
import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';

class UserSearchView extends StatefulWidget {
  const UserSearchView({super.key});

  @override
  State<UserSearchView> createState() => _UserSearchViewState();
}

class _UserSearchViewState extends State<UserSearchView> {
  final UserController _controller = UserController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = false;
  bool hasSearched = false;
  String? userId; // Asumiendo que se cargará luego para el Footer

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    userId = await AccountController().getCurrentUserId();
    setState(() {});
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    final results = await _controller.searchUsers(query);

    setState(() {
      filteredUsers = results;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Footer(
          selectedIndex: 0, 
          onItemTapped: (index) {
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserSearchView()),
                );
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                );
                break;
              case 4:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserProfileView(userId: userId!)),
                );
                break;
            }
          },
        ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Background(
          title: '',
          showRowIcon: false,
          showNotificationIcon: false,
          onBack: () {
            Navigator.pop(context);
          },
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar Usuario',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF112363), width: 2),
                  ),
                ),
                onChanged: _searchUsers,
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!hasSearched)
                const Expanded(
                  child: Center(
                    child: Text(
                      '¡No dejes para mañana lo que puedas leer hoy!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (filteredUsers.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No se encontraron usuarios.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileView(userId: user['id']),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFF112363),
                              width: 3,
                            ),
                          ),
                          child: ListTile(
                            leading: ClipOval(
                              child: Image.network(
                                user['image'] ?? 'assets/images/default.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(user['userName'] ?? 'Sin nombre de usuario'),
                            subtitle: Text(user['name'] ?? 'Sin nombre completo'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
