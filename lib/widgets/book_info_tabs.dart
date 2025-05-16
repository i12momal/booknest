import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/geolocation_controller.dart';
import 'package:booknest/controllers/review_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/models/geolocation_model.dart';
import 'package:booknest/entities/models/review_model.dart';
import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/views/add_review_view.dart';
import 'package:booknest/views/edit_review_view.dart';
import 'package:booknest/views/geolocation_view.dart';
import 'package:booknest/views/user_profile_view.dart';
import 'package:booknest/widgets/review_item.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BookInfoTabs extends StatefulWidget {
  final Book book;
  final bool isOwner;
  final bool reloadReviews;

  const BookInfoTabs({
    super.key,
    required this.book,
    required this.isOwner,
    required this.reloadReviews,
  });

  @override
  State<BookInfoTabs> createState() => _BookInfoTabsState();
}

class _BookInfoTabsState extends State<BookInfoTabs> {
  late Future<List<Review>> _reviewsFuture;
  String? _userId;
  String userName = '';

  Geolocation? _ownerGeo;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = fetchReviews();
    _loadUserId();
  }

  @override
  void didUpdateWidget(covariant BookInfoTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadReviews != oldWidget.reloadReviews && widget.reloadReviews) {
      setState(() {
        _reviewsFuture = fetchReviews();
        _loadUserId();
      });
    }
  }

  void _loadUserId() async {
    final id = await AccountController().getCurrentUserId();
    final result = await UserController().getUserNameById(widget.book.ownerId);

    if (result['success'] == true) {
      Geolocation? geo;
      try {
        if (id != widget.book.ownerId) {
          geo = await GeolocationController().getUserGeolocation(widget.book.ownerId);
        }
      } catch (e) {
        print('Error al obtener geolocalización: $e');
      }

      setState(() {
        _userId = id;
        userName = result['data']['userName'];
        _ownerGeo = geo;
      });
    } else {
      print(result['message']);
    }
  }




  Future<List<Review>> fetchReviews() async {
    return await ReviewController().getReviews(widget.book.id);
  }

  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 35),
          const TabBar(
            indicatorColor: Color(0xFF112363),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.edit, size: 16), text: 'Detalles'),
              Tab(icon: Icon(Icons.lock, size: 16), text: 'Reseñas y valoraciones'),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: FutureBuilder<List<Review>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar las reseñas.'));
                }

                final reviews = snapshot.data ?? [];

                return TabBarView(
                  children: [
                    _BookDetailsTab(book: widget.book, userName: userName, currentUser: _userId, ownerGeo: _ownerGeo),
                    Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _BookReviewsTab(
                            book: widget.book,
                            isOwner: widget.isOwner,
                            reviews: reviews,
                            currentUserId: _userId ?? '',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class _BookDetailsTab extends StatelessWidget {
  final Book book;
  final String userName;
  final String? currentUser;
  final Geolocation? ownerGeo;

  const _BookDetailsTab({required this.book, required this.userName, this.currentUser, this.ownerGeo});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(currentUser != book.ownerId)
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileView(userId: book.ownerId),
                      ),
                    );
                  },
                  child: Text(
                    "Propietario: $userName",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                if (ownerGeo != null && ownerGeo!.geolocationEnabled == true) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GeolocationMap(
                            focusLocation: LatLng(ownerGeo!.latitude, ownerGeo!.longitude),
                            focusedUser: ownerGeo,
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.location_on, color: Colors.red),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.blue),
              const SizedBox(width: 8),
              Text("${book.pagesNumber} páginas", style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.language, color: Colors.blue),
              const SizedBox(width: 8),
              Text(book.language, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2140AF), Color(0xFF6F8DEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Resumen",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      book.summary.isNotEmpty
                          ? book.summary
                          : "Este libro no tiene un resumen disponible.",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}






class _BookReviewsTab extends StatefulWidget {
  final Book book;
  final bool isOwner;
  final List<Review> reviews;
  final String? currentUserId; 

  const _BookReviewsTab({
    required this.book,
    required this.isOwner,
    required this.reviews,
    required this.currentUserId,
  });

  @override
  State<_BookReviewsTab> createState() => _BookReviewsTabState();
}

class _BookReviewsTabState extends State<_BookReviewsTab> {
  int _currentPage = 0;
  static const int _reviewsPerPage = 10;

  List<Review> _reviews = [];
  bool _isLoading = true;

  bool _showOnlyMyReviews = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final newReviews = await ReviewController().getReviews(widget.book.id);
    setState(() {
      _reviews = newReviews;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _showOnlyMyReviews
    ? _reviews.where((review) => review.userId == widget.currentUserId).toList()
    : _reviews;

    final totalPages = (reviews.length / _reviewsPerPage).ceil();
    final startIndex = _currentPage * _reviewsPerPage;
    final endIndex = (startIndex + _reviewsPerPage) < reviews.length
        ? (startIndex + _reviewsPerPage)
        : reviews.length;

    final currentReviews = reviews.sublist(startIndex, endIndex);

    return Column(
      children: [
        if (!widget.isOwner)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: Icon(
                    _showOnlyMyReviews ? Icons.check_box : Icons.check_box_outline_blank,
                    color: const Color(0xFF112363),
                  ),
                  label: const Text(
                    'Mostrar mis reseñas',
                    style: TextStyle(color: Color(0xFF112363)),
                  ),
                  onPressed: () {
                    setState(() {
                      _showOnlyMyReviews = !_showOnlyMyReviews;
                      _currentPage = 0;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF112363), size: 30),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddReviewView(book: widget.book),
                      ),
                    ).then((result) {
                      if (result == true) {
                        _loadReviews();
                      }
                    });
                  },
                ),
              ],
            ),
          ),


        if (_isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (reviews.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No hay reseñas disponibles.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          Flexible(
            child: ListView.builder(
              itemCount: currentReviews.length,
              itemBuilder: (context, index) {
                final review = currentReviews[index];

                return FutureBuilder<User?>(
                  future: UserController().getUserById(review.userId.toString()),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState != ConnectionState.done) {
                      return const SizedBox();
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData) {
                      return const ListTile(title: Text('Usuario no disponible'));
                    }

                    final user = userSnapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReviewItem(
                            name: user.name,
                            rating: review.rating,
                            comment: review.comment,
                            imageUrl: user.image ?? '',
                            isOwner: review.userId == widget.currentUserId,
                            onEdit: () => _editReview(review), 
                            onDelete: () => _confirmDeleteReview(review), 
                          )

                        ],
                      ),
                    );
                  },
                );

              },
            ),
          ),

          // Paginación
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                        }
                      : null,
                ),
                Text(
                  'Página ${_currentPage + 1} de $totalPages',
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _currentPage < totalPages - 1
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _editReview(Review review) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReviewView(book: widget.book, review: review),
      ),
    );

    if (result == true) {
      _loadReviews();
    }
  }


  void _confirmDeleteReview(Review review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reseña'),
        content: const Text('¿Estás seguro de que quieres eliminar esta reseña?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ReviewController().deleteReview(review.id);
        _loadReviews(); // Recargar la lista después de eliminar
       SuccessDialog.show(
        context,
        'Operación Exitosa',
        '¡La reseña ha sido eliminada correctamente!',
        () {},
      );
      } catch (e) {
        SuccessDialog.show(
          context,
          'Error en la Operación',
          'Ha ocurrido un error al intentar eliminar la reseña',
          () {},
        );
      }
    }
  }
}
