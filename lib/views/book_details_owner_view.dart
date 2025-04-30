import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/controllers/review_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/models/review_model.dart';
import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/views/add_review_view.dart';
import 'package:booknest/views/edit_book_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/review_item.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:booknest/widgets/tap_bubble_text.dart';
import 'package:flutter/material.dart';


// Vista para la acción de Ver los detalles de un libro
class BookDetailsOwnerView extends StatefulWidget {
  final int bookId;
  const BookDetailsOwnerView({super.key, required this.bookId});

  @override
  State<BookDetailsOwnerView> createState() => _BookDetailsOwnerViewState();
}

class _BookDetailsOwnerViewState extends State<BookDetailsOwnerView> {
  late Future<Book?> _bookFuture;
  late Future<String?> _currentUserFuture;
  final _controller = BookController();
  final loancontroller = LoanController();
  final bool _shouldReloadReviews = false;

  late Future<List<String>> _loanedFormatsFuture;

  @override
  void initState() {
    super.initState();
    _bookFuture = _controller.getBookById(widget.bookId);
    _currentUserFuture = AccountController().getCurrentUserId();
    _loanedFormatsFuture = loancontroller.fetchLoanedFormats(widget.bookId);
  }

  void _showSuccessDialog(BuildContext context) {
    SuccessDialog.show(
      context,
      'Solicitud de Préstamo Exitosa',
      '¡Tu solicitud de préstamo ha sido enviada exitosamente!',
      () {},
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    SuccessDialog.show(
      context,
      'Error en la Solicitud',
      message,
      () {},
    );
  }

  Future<String?> _showFormatDialog(BuildContext context, List<String> formats) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text("Seleccione un formato"),
          children: formats.map((format) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, format),
              child: Text(format),
            );
          }).toList(),
        );
      },
    );
  }

  String getAvailabilityStatus(Book book, List<String> loanedFormats) {
    // Obtener los formatos del libro (en minúsculas y sin espacios extra)
    final List<String> formats = book.format
        .split(',')
        .map((f) => f.trim().toLowerCase())
        .where((f) => f.isNotEmpty)
        .toList();

    // Filtrar los formatos disponibles
    final List<String> disponibles = formats
        .where((format) => !loanedFormats.map((f) => f.toLowerCase()).contains(format))
        .toList();

    // Lógica para determinar el estado de disponibilidad
    if (disponibles.isEmpty) {
      return 'Prestado';  // Si no hay formatos disponibles, el libro está prestado
    } else if (disponibles.length == formats.length) {
      return 'Disponible';  // Si todos los formatos están disponibles
    } else if (disponibles.length == 1) {
      final formatCapitalized = disponibles.first[0].toUpperCase() + disponibles.first.substring(1);
      return 'Disponible en formato $formatCapitalized';  // Si solo hay un formato disponible
    } else {
      // Si hay más de un formato disponible, especificar uno
      if (disponibles.contains('físico') && !disponibles.contains('digital')) {
        return 'Disponible en formato Físico';
      } else if (disponibles.contains('digital') && !disponibles.contains('físico')) {
        return 'Disponible en formato Digital';
      } else {
        return 'Disponible';  // Si hay más de un formato disponible (físico y digital)
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return FutureBuilder<Book?>(
      future: _bookFuture,
      builder: (context, bookSnapshot) {
        if (bookSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (bookSnapshot.hasError || !bookSnapshot.hasData) {
          return const Scaffold(body: Center(child: Text("Error cargando el libro")));
        }

        final book = bookSnapshot.data!;

        return FutureBuilder<String?>(
          future: _currentUserFuture,
          builder: (context, userIdSnapshot) {
            if (userIdSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            } else if (userIdSnapshot.hasError || !userIdSnapshot.hasData) {
              return const Scaffold(body: Center(child: Text("Error cargando el usuario")));
            }

            final currentUserId = userIdSnapshot.data;
            final isOwner = book.ownerId.toString() == currentUserId;

            // FutureBuilder para obtener los formatos prestados
            return FutureBuilder<List<String>>(
              future: _loanedFormatsFuture, // Carga los formatos prestados
              builder: (context, loanedSnapshot) {
                if (loanedSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                } else if (loanedSnapshot.hasError || !loanedSnapshot.hasData) {
                  return const Scaffold(body: Center(child: Text("Error cargando disponibilidad")));
                }

                final loanedFormats = loanedSnapshot.data!;

                // Usar la lógica de disponibilidad para obtener el estado
                final availabilityStatus = getAvailabilityStatus(book, loanedFormats);

                return Background(
                  title: 'Detalles del libro',
                  onBack: () => Navigator.pop(context),
                  child: Column(
                    children: [
                      
                      _BookHeader(book: book, isOwner: isOwner, loanedFormats: loanedFormats),
                      Expanded(
                        child: BookInfoTabs(
                          book: book,
                          isOwner: isOwner,
                          reloadReviews: _shouldReloadReviews,
                        ),
                      ),
                      if (!isOwner && availabilityStatus != 'Prestado')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                // Obtener los formatos disponibles del libro (campo 'format' en la tabla Book)
                                final formats = book.format.split(',').map((e) => e.trim()).toList();

                                // 1. Filtrar los formatos disponibles (es decir, los que no están prestados)
                                List<String> availableFormats = await loancontroller.fetchAvailableFormats(book.id, formats);

                                if (availableFormats.isEmpty) {
                                  _showErrorDialog(context, 'No hay formatos disponibles para préstamo.');
                                  return;
                                }

                                // 2. Seleccionar el formato
                                String? selectedFormat;
                                if (availableFormats.length == 1) {
                                  selectedFormat = availableFormats.first;
                                } else {
                                  selectedFormat = await _showFormatDialog(context, availableFormats);
                                  if (selectedFormat == null || selectedFormat.isEmpty) {
                                    _showErrorDialog(context, 'Debes seleccionar un formato válido.');
                                    return;
                                  }
                                }

                                // 3. Enviar la solicitud de préstamo
                                final response = await loancontroller.requestLoan(book, selectedFormat);

                                if (!context.mounted) return;

                                if (response['success']) {
                                  _showSuccessDialog(context);
                                } else {
                                  _showErrorDialog(context, response['message']);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFAD0000),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.1,
                                  vertical: screenHeight * 0.02,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: const BorderSide(color: Color(0xFF700101), width: 3),
                                ),
                              ),
                              child: const Text(
                                "Solicitar Préstamo",
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}






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

  @override
  void initState() {
    super.initState();
    // Inicializamos las reseñas
    _reviewsFuture = fetchReviews();
  }

  @override
  void didUpdateWidget(covariant BookInfoTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si las reseñas necesitan recargarse
    if (widget.reloadReviews != oldWidget.reloadReviews && widget.reloadReviews) {
      setState(() {
        _reviewsFuture = fetchReviews();
      });
    }
  }

  Future<List<Review>> fetchReviews() async {
    var response = await ReviewController().getReviews(widget.book.id);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const SizedBox(height: 40),
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
            child: TabBarView(
              children: [
                _BookDetailsTab(book: widget.book),
                _BookReviewsTab(book: widget.book, isOwner: widget.isOwner, reviewsFuture: _reviewsFuture),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






class _BookHeader extends StatelessWidget {
  final Book book;
  final bool isOwner;
  final List<String> loanedFormats;

  const _BookHeader({
    required this.book,
    required this.isOwner,
    required this.loanedFormats,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> formats = book.format
        .split(',')
        .map((f) => f.trim().toLowerCase())
        .where((f) => f.isNotEmpty)
        .toList();

    final List<String> disponibles = formats
        .where((format) => !loanedFormats.map((f) => f.toLowerCase()).contains(format))
        .toList();

    String availabilityStatus;
    if (disponibles.isEmpty) {
      availabilityStatus = 'Prestado';
    } else if (disponibles.length == formats.length) {
      availabilityStatus = 'Disponible';
    } else if (disponibles.length == 1) {
      final formatCapitalized = disponibles.first[0].toUpperCase() + disponibles.first.substring(1);
      availabilityStatus = 'Disponible en formato $formatCapitalized';
    } else {
      // Si hay más de uno disponible pero no todos, especificamos uno
      if (disponibles.contains('físico') && !disponibles.contains('digital')) {
        availabilityStatus = 'Disponible en formato Físico';
      } else if (disponibles.contains('digital') && !disponibles.contains('físico')) {
        availabilityStatus = 'Disponible en formato Digital';
      } else {
        availabilityStatus = 'Disponible';
      }
    }

    debugPrint('--- DEBUG DISPONIBILIDAD ---');
    debugPrint('book.format: ${book.format}');
    debugPrint('loanedFormats: $loanedFormats');
    debugPrint('formats: $formats');
    debugPrint('disponibles: $disponibles');
    debugPrint('availabilityStatus: $availabilityStatus');
    debugPrint('----------------------------');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF112363)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () {
                if (isOwner) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditBookView(bookId: book.id),
                    ),
                  );
                }
              },
              child: Image.network(
                book.cover,
                height: 140,
                width: 90,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isOwner) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditBookView(bookId: book.id),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TapBubbleText(
                    text: book.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TapBubbleText(
                          text: book.author,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(book.isbn),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (formats.contains("físico"))
                        const Row(
                          children: [
                            Icon(Icons.book, size: 18),
                            SizedBox(width: 4),
                            Text("Físico"),
                          ],
                        ),
                      if (formats.contains("físico") && formats.contains("digital"))
                        const SizedBox(width: 12),
                      if (formats.contains("digital"))
                        const Row(
                          children: [
                            Icon(Icons.tablet_android, size: 18),
                            SizedBox(width: 4),
                            Text("Digital"),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (availabilityStatus == 'Disponible') ...[
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 4),
                        const Text("Disponible"),
                      ] else if (availabilityStatus.startsWith('Disponible en formato')) ...[
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 4),
                        Text(availabilityStatus),
                      ] else if (availabilityStatus == 'Prestado') ...[
                        const Icon(Icons.cancel, color: Colors.red, size: 18),
                        const SizedBox(width: 4),
                        const Text("Prestado", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        GestureDetector(
                          child: const Text(
                            "Información del préstamo",
                            style: TextStyle(
                              color: Color(0xFF112363),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}














class _BookDetailsTab extends StatelessWidget {
  final Book book;

  const _BookDetailsTab({required this.book});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
  final Future<List<Review>> reviewsFuture;

  const _BookReviewsTab({required this.book, required this.isOwner, required this.reviewsFuture});

  @override
  _BookReviewsTabState createState() => _BookReviewsTabState();
}

class _BookReviewsTabState extends State<_BookReviewsTab> {
  late Future<List<Review>> _reviewsFuture;
  int _currentPage = 0;
  static const int _reviewsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = widget.reviewsFuture;
  }

  void _refreshReviews() {
    setState(() {
      _reviewsFuture = ReviewController().getReviews(widget.book.id);
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            children: [
              if (!widget.isOwner)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 4.0),
                    child: IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF112363), size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddReviewView(book: widget.book),
                          ),
                        ).then((_) {
                          _refreshReviews();
                        });
                      },
                    ),
                  ),
                ),
              const Expanded(
                child: Center(
                  child: Text(
                    'No hay reseñas disponibles.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ],
          );
        } else {
          final reviews = snapshot.data!;
          final totalPages = (reviews.length / _reviewsPerPage).ceil();
          final startIndex = _currentPage * _reviewsPerPage;
          final endIndex = (startIndex + _reviewsPerPage) < reviews.length
              ? (startIndex + _reviewsPerPage)
              : reviews.length;

          final currentReviews = reviews.sublist(startIndex, endIndex);

          return Column(
            children: [
              if (!widget.isOwner)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 4.0),
                    child: IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF112363), size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddReviewView(book: widget.book),
                          ),
                        ).then((_) {
                          _refreshReviews();
                        });
                      },
                    ),
                  ),
                ),
              Flexible(
                child: ListView.builder(
                  itemCount: currentReviews.length,
                  itemBuilder: (context, index) {
                    final review = currentReviews[index];
                    return FutureBuilder<User?>(
                      future: UserController().getUserById(review.userId.toString()),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (userSnapshot.hasError) {
                          return Center(child: Text('Error: ${userSnapshot.error}'));
                        } else if (!userSnapshot.hasData || userSnapshot.data == null) {
                          return const Center(child: Text('Usuario no encontrado'));
                        } else {
                          var user = userSnapshot.data!;
                          String userName = user.name;
                          String imageUrl = user.image ?? '';

                          return ReviewItem(
                            name: userName,
                            rating: review.rating,
                            comment: review.comment,
                            imageUrl: imageUrl,
                          );
                        }
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
          );
        }
      },
    );
  }
}
