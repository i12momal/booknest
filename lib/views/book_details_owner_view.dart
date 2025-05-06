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
import 'package:booknest/views/edit_review_view.dart';
import 'package:booknest/views/favorites_view.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/owner_profile_view.dart';
import 'package:booknest/views/user_profile_view.dart';
import 'package:booknest/views/user_search_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/favorite_icon.dart';
import 'package:booknest/widgets/footer.dart';
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
  bool _loanRequestSent = false;

  int? notificationId;

  bool _isSendingRequest = false;
  bool _isDeletingRequest = false;

  @override
  void initState() {
    super.initState();
    _bookFuture = _controller.getBookById(widget.bookId);
    _currentUserFuture = AccountController().getCurrentUserId();
    _loanedFormatsFuture = loancontroller.fetchLoanedFormats(widget.bookId);
    _checkIfLoanRequestExists();
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

  Future<void> _checkIfLoanRequestExists() async {
    final userId = await AccountController().getCurrentUserId();
    if (userId != null) {
      final result = await loancontroller.checkExistingLoanRequest(widget.bookId, userId);
      if (mounted) {
        setState(() {
          _loanRequestSent = result['exists'];
          notificationId = result['notificationId'];
        });
      }
    }
  }

  void _confirmDeleteLoanRequest(BuildContext context, int bookId, int? notificationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Solicitud"),
        content: const Text("¿Estás seguro de que deseas eliminar la solicitud de préstamo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await loancontroller.cancelLoanRequest(bookId, notificationId);

      if (!context.mounted) return;

      if (response['success']) {
        setState(() {
          _loanRequestSent = false;
        });
         SuccessDialog.show(
          context,
          'Operación Exitosa',
          '¡Tu solicitud de préstamo ha sido eliminada correctamente!',
          () {},
        );
      } else {
        _showErrorDialog(context, response['message']);
      }
    }
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
      return 'Disponible: formato $formatCapitalized';  // Si solo hay un formato disponible
    } else {
      // Si hay más de un formato disponible, especificar uno
      if (disponibles.contains('físico') && !disponibles.contains('digital')) {
        return 'Disponible: formato Físico';
      } else if (disponibles.contains('digital') && !disponibles.contains('físico')) {
        return 'Disponible: formato Digital';
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
                return Scaffold(
                  body: Background(
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
                              child:  _loanRequestSent
                              ? ElevatedButton(
                                  onPressed: () {
                                    setState(() => _isDeletingRequest = true);
                                    _confirmDeleteLoanRequest(context, book.id, notificationId);
                                    if (mounted) setState(() => _isDeletingRequest = false);
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
                                  child: _isDeletingRequest
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        "Eliminar Solicitud de Préstamo",
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),

                              )
                              : ElevatedButton(
                                onPressed: () async {
                                  setState(() => _isSendingRequest = true);

                                  // Obtener los formatos disponibles del libro (campo 'format' en la tabla Book)
                                  final formats = book.format.split(',').map((e) => e.trim()).toList();

                                  // 1. Filtrar los formatos disponibles (es decir, los que no están prestados)
                                  List<String> availableFormats = await loancontroller.fetchAvailableFormats(book.id, formats);
                                  if (!context.mounted) return;
                                  if (availableFormats.isEmpty) {
                                    _showErrorDialog(context, 'No hay formatos disponibles para préstamo.');
                                    setState(() => _isSendingRequest = false);
                                    return;
                                  }

                                  // 2. Seleccionar el formato
                                  String? selectedFormat;
                                  if (availableFormats.length == 1) {
                                    selectedFormat = availableFormats.first;
                                  } else {
                                    selectedFormat = await _showFormatDialog(context, availableFormats);
                                    if (!context.mounted) return;
                                    if (selectedFormat == null || selectedFormat.isEmpty) {
                                      _showErrorDialog(context, 'Debes seleccionar un formato válido.');
                                      setState(() => _isSendingRequest = false);
                                      return;
                                    }
                                  }

                                  // 3. Enviar la solicitud de préstamo
                                  final response = await loancontroller.requestLoan(book, selectedFormat);

                                  if (!context.mounted) return;

                                  if (response['success']) {
                                    setState(() {
                                      _loanRequestSent = true;
                                      notificationId = int.tryParse(response['notificationId']);
                                    });
                                    _showSuccessDialog(context);
                                  } else {
                                    _showErrorDialog(context, response['message']);
                                  }
                                  setState(() => _isSendingRequest = false);
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
                                child: _isSendingRequest
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "Solicitar Préstamo",
                                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),

                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
                            MaterialPageRoute(builder: (context) => const FavoritesView()),
                          );
                          break;
                        case 4:
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => OwnerProfileView(userId: currentUserId!)),
                          );
                          break;
                      }
                    },
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
  String? _userId;

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
    setState(() {
      _userId = id;
    });
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
                    _BookDetailsTab(book: widget.book),
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



class _BookHeader extends StatelessWidget {
  final Book book;
  final bool isOwner;
  final List<String> loanedFormats;

  const _BookHeader({
    required this.book,
    required this.isOwner,
    required this.loanedFormats,
  });

  Future<bool?> _showLoanInfoPopup(BuildContext context) async {
    List<Map<String, dynamic>> loans = await LoanController().getLoansByBookId(book.id);

    if (loans.isEmpty) return false;

    final PageController pageController = PageController();
    int currentPage = 0;

    void showSuccessDialog(BuildContext context, int bookId) {
      SuccessDialog.show(
        context,
        'Operación Exitosa',
        '¡El libro ha sido devuelto con éxito!',
        () {
          Navigator.pop(context);
          Future.microtask(() {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailsOwnerView(bookId: bookId),
              ),
            );
          });
        },
      );
    }


    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF112363), width: 3), // Borde azul
              ),
              child: SizedBox(
                width: 320,
                height: 340,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        // Línea de progreso centrada y ajustada dentro del borde
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: List.generate(
                              loans.length,
                              (index) => Expanded(
                                child: Container(
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: index <= currentPage
                                        ? const Color(0xFF700101)
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: PageView.builder(
                            controller: pageController,
                            onPageChanged: (index) {
                              setState(() {
                                currentPage = index;
                              });
                            },
                            itemCount: loans.length,
                            itemBuilder: (context, index) {
                              final loan = loans[index];
                              final formattedStart = loan['startDate'].split('T').first;
                              final formattedEnd = loan['endDate'].split('T').first;

                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: FutureBuilder<User?>(
                                  future: isOwner
                                      ? UserController().getUserById(loan['currentHolderId'].toString())
                                      : Future.value(null),
                                  builder: (context, userSnapshot) {
                                    final borrowerName = isOwner
                                        ? (userSnapshot.data?.userName ?? 'Desconocido')
                                        : null;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isOwner) ...[
                                          const Text(
                                            "Prestado al usuario:",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                           GestureDetector(
                                            onTap: () {
                                              // Si quieres redirigir al perfil del usuario cuando se hace clic en el userName
                                              if (userSnapshot.hasData && userSnapshot.data != null) {
                                                final userId = userSnapshot.data!.id;
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => UserProfileView(userId: userId),
                                                  ),
                                                );
                                              }
                                            },
                                          child: Text(borrowerName ?? 'Desconocido', style: const TextStyle(color: Color(0xFF112363), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),),),
                                          const SizedBox(height: 12),
                                        ],
                                        const Text("Formato:", style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(loan['format']),
                                        const SizedBox(height: 12),
                                        const Text("Fecha de inicio del préstamo:", style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(formattedStart),
                                        const SizedBox(height: 12),
                                        const Text("Fecha de finalización del préstamo:", style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(formattedEnd),

                                        if (loan['format'].toString().toLowerCase().trim() == 'físico')...[
                                          const SizedBox(height: 12),
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                bool? confirm = await _showConfirmReturnDialog(context);
                                                if (confirm == true) {
                                                  _returnPhysicalBook(loan['id']);
                                                  showSuccessDialog(context, loan['bookId']);
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF700101),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(30),
                                                  side: const BorderSide(color: Color(0xFF700101), width: 3),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 7),
                                              ),
                                              child: const Text(
                                                "Marcar como devuelto",
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ]

                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    // Botón de cierre (X)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF112363)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return null;
  }

  Future<bool?> _showConfirmReturnDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Estás seguro de que deseas marcar este libro como devuelto?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Sí, devolver"),
          ),
        ],
      ),
    );
  }

  void _returnPhysicalBook(int loanId) async {
    await LoanController().updateLoanState(loanId, 'Devuelto');
  }
  

  @override
  Widget build(BuildContext context) {
    final List<String> formats = book.format.split(',').map((f) => f.trim().toLowerCase()).where((f) => f.isNotEmpty).toList();

    final List<String> disponibles = formats.where((format) => !loanedFormats.map((f) => f.toLowerCase()).contains(format)).toList();

    String availabilityStatus;
    if (disponibles.isEmpty) {
      availabilityStatus = 'Prestado';
    } else if (disponibles.length == formats.length) {
      availabilityStatus = 'Disponible';
    } else if (disponibles.length == 1) {
      final formatCapitalized = disponibles.first[0].toUpperCase() + disponibles.first.substring(1);
      availabilityStatus = 'Disponible: formato $formatCapitalized';
    } else {
      if (disponibles.contains('físico') && !disponibles.contains('digital')) {
        availabilityStatus = 'Disponible: formato Físico';
      } else if (disponibles.contains('digital') && !disponibles.contains('físico')) {
        availabilityStatus = 'Disponible: formato Digital';
      } else {
        availabilityStatus = 'Disponible';
      }
    }

    return Stack(
      children: [
        Container(
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
                child: Stack(
                  children: [
                    GestureDetector(
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
                              ] else if (availabilityStatus.startsWith('Disponible: formato')) ...[
                                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                const SizedBox(width: 4),
                                Text(availabilityStatus),
                              ] else if (availabilityStatus == 'Prestado') ...[
                                const Icon(Icons.cancel, color: Colors.red, size: 18),
                                const SizedBox(width: 4),
                                const Text("Prestado", style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 12),
                                GestureDetector(
                                 onTap: () async {
                                  final result = await _showLoanInfoPopup(context);
                                  if (result == true) {
                                    Navigator.of(context).pop();
                                  }
                                },

                                  child: const Text(
                                    "Información préstamo",
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
                    if (!isOwner)
                      Positioned(
                        bottom: -14,
                        right: -14,
                        child: FavoriteIcon(book: book),
                      ),
                    if (isOwner) // La papelera solo se muestra si ERES el propietario
                      Positioned(
                        bottom: 0, 
                        right: 0,  
                        child: GestureDetector(
                          onTap: () {
                            final parentContext = context;
                            showDialog(
                              context: parentContext,
                              builder: (context) => AlertDialog(
                                title: const Text('Eliminar libro'),
                                content: const Text('¿Estás seguro de que quieres eliminar este libro?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await BookController().deleteBook(book.id);
                                      if (parentContext.mounted) {
                                        SuccessDialog.show(
                                          parentContext,
                                          'Operación Exitosa',
                                          'El libro ha sido eliminado correctamente',
                                          () {
                                            Navigator.of(parentContext).pop();
                                            Navigator.of(parentContext).pop(book.id);
                                          },
                                        );
                                      }
                                    },
                                    child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ), 
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
