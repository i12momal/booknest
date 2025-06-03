import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/views/add_book_view.dart';
import 'package:booknest/views/edit_book_view.dart';
import 'package:booknest/views/favorites_view.dart';
import 'package:booknest/views/geolocation_view.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/owner_profile_view.dart';
import 'package:booknest/views/user_profile_view.dart';
import 'package:booknest/views/user_search_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/book_info_tabs.dart';
import 'package:booknest/widgets/favorite_icon.dart';
import 'package:booknest/widgets/footer.dart';
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
  int? principalLoanId;

  late Future<List<Map<String, String>>> _loanedFormatsFuture;
  bool _loanRequestSent = false;

  int? notificationId;

  String? _selectedFormat;

  bool _isSendingRequest = false;
  bool _isDeletingRequest = false;

  @override
  void initState() {
    super.initState();
    _bookFuture = _controller.getBookById(widget.bookId);
    _currentUserFuture = AccountController().getCurrentUserId();
    _loanedFormatsFuture = loancontroller.getLoanedFormatsAndStates(widget.bookId);
    _checkIfLoanRequestExists();
  }

  // Función para mostrar el diálogo de éxito al realizar una solicitud de préstamo
  void _showSuccessDialog(BuildContext context) {
    SuccessDialog.show(
      context,
      'Solicitud de Préstamo Exitosa',
      '¡Tu solicitud de préstamo ha sido enviada exitosamente!',
      () {
        Future.microtask(() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsOwnerView(bookId: widget.bookId),
            ),
          );
        });
      },
    );
  }

  // Función para mostrar el diálogo de error al realizar una solicitud de préstamo
  void _showErrorDialog(BuildContext context, String message) {
    SuccessDialog.show(
      context,
      'Error en la Solicitud',
      message,
      () {},
    );
  }

  // Función para comprobar si ya existe una solicitud de préstamo para ese libro
  Future<void> _checkIfLoanRequestExists() async {
    final userId = await AccountController().getCurrentUserId();
    if (userId != null) {
      final result = await loancontroller.checkExistingLoanRequest(widget.bookId, userId);
      if (mounted) {
        setState(() {
          _loanRequestSent = result['exists'];
          notificationId = result['notificationId'];
          _selectedFormat = result['format'];
        });
      }

    }
  }

  // Función para confirmar la eliminación de una solicitud de préstamos
  Future<void> _confirmDeleteLoanRequest(BuildContext context, int bookId, int? notificationId, String? format) async {
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
      final response = await loancontroller.cancelLoanRequest(bookId, notificationId, format);

      if (!context.mounted) return;

      if (response['success']) {
        await _checkIfLoanRequestExists();
        setState(() {
          _loanRequestSent = false;
        });
         SuccessDialog.show(
          context,
          'Operación Exitosa',
          '¡Tu solicitud de préstamo ha sido eliminada correctamente!',
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
      } else {
        _showErrorDialog(context, response['message']);
      }
    }
  }

  // Función que muestra un diálogo con los formatos del libro (en caso de que tenga dos)
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

  // Función para establecer la disponiblidad de un libro según el estado de sus formatos
  String getAvailabilityStatus(Book book, List<String> loanedFormats) {
    // Obtener los formatos del libro
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
      return formatCapitalized;  // Si solo hay un formato disponible
    } else {
      // Si hay más de un formato disponible, especificar uno
      if (disponibles.contains('físico') && !disponibles.contains('digital')) {
        return 'Físico';
      } else if (disponibles.contains('digital') && !disponibles.contains('físico')) {
        return 'Digital';
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
            return FutureBuilder<List<Map<String, String>>>(
              future: _loanedFormatsFuture, // Carga los formatos prestados
              builder: (context, loanedSnapshot) {
                if (loanedSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                } else if (loanedSnapshot.hasError || !loanedSnapshot.hasData) {
                  return const Scaffold(body: Center(child: Text("Error cargando disponibilidad")));
                }

                final loanedFormats = loanedSnapshot.data!;
                final formats = loanedFormats.map((e) => e['format']!).toList();

                // Usar la lógica de disponibilidad para obtener el estado
                final availabilityStatus = getAvailabilityStatus(book, formats);
                return Scaffold(
                  body: Background(
                    title: 'Detalles del libro',
                    onBack: () => Navigator.pop(context),
                    child: Column(
                      children: [
                        _BookHeader(book: book, isOwner: isOwner, loanedFormats: loanedFormats),
                        Expanded(
                          child: BookInfoTabs(book: book, isOwner: isOwner, reloadReviews: _shouldReloadReviews),
                        ),
                        if (!isOwner && (availabilityStatus != 'Prestado' || _loanRequestSent))
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth < 600 ? double.infinity : 500,
                                ),
                                child: ElevatedButton(
                                  onPressed: _loanRequestSent
                                      ? () async {
                                          setState(() => _isDeletingRequest = true);
                                          await _confirmDeleteLoanRequest(context, book.id, notificationId, _selectedFormat);
                                          if (mounted) setState(() => _isDeletingRequest = false);
                                        }
                                      : () async {
                                          setState(() => _isSendingRequest = true);

                                          final formats = book.format.split(',').map((e) => e.trim()).toList();
                                          List<String> availableFormats = await loancontroller.fetchAvailableFormats(book.id, formats);

                                          if (!context.mounted) return;
                                          if (availableFormats.isEmpty) {
                                            _showErrorDialog(context, 'No hay formatos disponibles para préstamo.');
                                            setState(() => _isSendingRequest = false);
                                            return;
                                          }

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
                                          // Físico
                                          if (selectedFormat.toLowerCase() == 'físico') {
                                            final userBooks = await _controller.getUserAvailablePhysicalBooks(currentUserId!);
                                            if (!context.mounted) return;

                                            // Primero, crea el préstamo principal
                                            final response = await loancontroller.requestLoan(book, selectedFormat, []);

                                            if (!response['success']) {
                                              _showErrorDialog(context, response['message']);
                                              setState(() => _isSendingRequest = false);
                                              return;
                                            }

                                            principalLoanId = response['data']['id'];
                                            if (!context.mounted) return;

                                            // Ahora que tenemos el ID, continuar con el diálogo
                                            final selectedBooks = await _showUserBookSelectionDialog(context, userBooks, widget.bookId, principalLoanId!);
                                            if (!context.mounted) return;

                                            if (selectedBooks == null) {
                                              setState(() => _isSendingRequest = false);
                                              return;
                                            }

                                            if (selectedBooks.isEmpty) {
                                              _showErrorDialog(context, 'Debes seleccionar al menos un libro físico para continuar.');
                                              setState(() => _isSendingRequest = false);
                                              return;
                                            }

                                            // Registrar los libros ofrecidos
                                            for (var book in selectedBooks) {
                                              BookController().changeState(book.id, 'Pendiente');
                                              await LoanController().requestOfferPhysicalBookLoan(book, principalLoanId!);
                                            }

                                            await _checkIfLoanRequestExists();
                                            _showSuccessDialog(context);
                                            setState(() => _isSendingRequest = false);
                                            return;
                                          }

                                          // Digital
                                          final response = await loancontroller.requestLoan(book, selectedFormat, null);
                                          if (!context.mounted) return;

                                          if (response['success']) {
                                            await _checkIfLoanRequestExists();
                                            _showSuccessDialog(context);
                                          } else {
                                            _showErrorDialog(context, response['message']);
                                          }
                                          setState(() => _isSendingRequest = false);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFAD0000),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: screenHeight * 0.020,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: const BorderSide(color: Color(0xFF700101), width: 3),
                                    ),
                                  ),
                                  child: (_loanRequestSent
                                      ? (_isDeletingRequest
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : const Text(
                                              "Eliminar Solicitud de Préstamo",
                                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                            ))
                                      : (_isSendingRequest
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : const Text(
                                              "Solicitar Préstamo",
                                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                            ))),
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
                            MaterialPageRoute(builder: (context) => const GeolocationMap()),
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

// Método que muestra el diálogo de selección de libros físicos del usuario a ofrecer en un intercambio físico
Future<List<Book>?> _showUserBookSelectionDialog(BuildContext context, List<Book> userBooks, int bookId, int principalLoanId) async {
  final selected = <Book>{};

  return await showDialog<List<Book>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF112363), width: 3),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Selecciona tus libros a ofrecer',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF112363)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddBookView(origin: 'book_details', bookId: bookId),
                  ),
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: userBooks.isEmpty
              ? const Text('No tienes libros físicos disponibles para incluir en la solicitud.')
              : ListView(
                  shrinkWrap: true,
                  children: userBooks.map((book) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        final isSelected = selected.contains(book);
                        return CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(book.title),
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              checked! ? selected.add(book) : selected.remove(book);
                            });
                          },
                        );
                      },
                    );
                  }).toList(),
                ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context, null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAD0000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Color(0xFF700101), width: 3),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (userBooks.isNotEmpty)
                ElevatedButton(
                  onPressed: () async{
                    Navigator.pop(context, selected.toList());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Color(0xFF700101), width: 3),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  ),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}



// Vista para la acción de Ver los datos generales de un libro
class _BookHeader extends StatelessWidget {
  final Book book;
  final bool isOwner;
  final List<Map<String, String>> loanedFormats;

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

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: 320,
              height: 360,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF709DFF), Color(0xFF0D1C5A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          "Información del préstamo",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Indicadores de progreso
                        Row(
                          children: List.generate(
                            loans.length,
                            (index) => Expanded(
                              child: Container(
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: index <= currentPage
                                      ? const Color(0xFF700101)
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(3),
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

                              return FutureBuilder<User?>(
                                future: isOwner
                                    ? UserController().getUserById(loan['currentHolderId'].toString())
                                    : Future.value(null),
                                builder: (context, userSnapshot) {
                                  final borrowerName = isOwner
                                      ? (userSnapshot.data?.userName ?? 'Desconocido')
                                      : null;

                                  return SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (isOwner) ...[
                                          const Text("Prestado a:",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () {
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
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              borrowerName ?? '',
                                              style: const TextStyle(
                                                color: Colors.blue, // Indicador clickeable
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                          const SizedBox(height: 12),
                                        ],
                                        const Text("Fecha Inicio Préstamo",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        _styledInput(formattedStart),
                                        const SizedBox(height: 12),
                                        const Text("Fecha Fin Préstamo",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        _styledInput(formattedEnd),
                                        const SizedBox(height: 12),
                                        const Text("Formato",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        _styledInput(loan['format']),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.red, size: 20),
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

// Widget para mostrar los campos de texto con diseño
Widget _styledInput(String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.black87),
    ),
  );
}


  @override
  Widget build(BuildContext context) {

    final List<String> allFormats = book.format.split(',').map((f) => f.trim().toLowerCase()).where((f) => f.isNotEmpty).toList();
    final List<String> acceptedFormats = loanedFormats.where((entry) => entry['state'] == 'Aceptado').map((entry) => entry['format']!).toList();
    final List<String> pendingFormats = loanedFormats.where((entry) => entry['state'] == 'Pendiente' && !acceptedFormats.contains(entry['format'])).map((entry) => entry['format']!).toList();
    final List<String> availableFormats = allFormats.where((f) => !acceptedFormats.contains(f) && !pendingFormats.contains(f)).toList();

    String availabilityStatus;

    if (availableFormats.isEmpty) {
      // No hay ningún formato disponible
      if (pendingFormats.isNotEmpty) {
        // Hay al menos un pendiente (podría ser combinado con Aceptado)
        availabilityStatus = 'Pendiente';
      } else {
        // Todos están aceptados
        availabilityStatus = 'Prestado';
      }
    } else if (availableFormats.length == allFormats.length) {
      availabilityStatus = 'Disponible';
    } else {
      // Hay algunos formatos disponibles
      if (availableFormats.contains('físico') && !availableFormats.contains('digital')) {
        availabilityStatus = 'Físico';
      } else if (availableFormats.contains('digital') && !availableFormats.contains('físico')) {
        availabilityStatus = 'Digital';
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
                              if (allFormats.contains("físico"))
                                const Row(
                                  children: [
                                    Icon(Icons.book, size: 18),
                                    SizedBox(width: 4),
                                    Text("Físico"),
                                  ],
                                ),
                              if (allFormats.contains("físico") && allFormats.contains("digital"))
                                const SizedBox(width: 12),
                              if (allFormats.contains("digital"))
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
                              if (availabilityStatus == 'Pendiente') ...[
                                const Icon(Icons.hourglass_empty, color: Colors.orange, size: 18),
                                const SizedBox(width: 4),
                                const Text("Pendiente"),
                              ]else if (availabilityStatus == 'Disponible') ...[
                                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                const SizedBox(width: 4),
                                const Text("Disponible"),
                              ] else if (availabilityStatus.startsWith('Físico') || availabilityStatus.startsWith('Digital') ) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    const SizedBox(width: 4),
                                    Text(availabilityStatus),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                if (isOwner) ...[
                                  const SizedBox(height: 4),
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
                                ],
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
                        bottom: -10, //-14
                        right: -10,
                        child: FavoriteIcon(book: book),
                      ),
                    if (isOwner) // La papelera solo se muestra si eres el propietario
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