import 'dart:io';
import 'dart:typed_data';
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/views/book_details_owner_view.dart';
import 'package:booknest/views/owner_profile_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/page_navigation.dart';
import 'package:booknest/widgets/book_info_form_add.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:booknest/widgets/genre_and_summary_selection.dart';

// Vista para la acción de Añadir un nuevo libro
class AddBookView extends StatefulWidget{
  final String origin;
  final int? bookId;
  const AddBookView ({super.key, required this.origin, this.bookId});

  @override
  State<AddBookView> createState() => _AddBookViewState();
}

class _AddBookViewState extends State<AddBookView>{
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _pagesNumberController = TextEditingController();
  final _languageController = TextEditingController();
  final _formatController = TextEditingController();
  final _summaryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _secondFormKey = GlobalKey<FormState>();

  final PageController _pageController = PageController();
  final CategoriesController _categoryController = CategoriesController();
  final BookController _bookController = BookController();

  String _message = '';
  String _summaryMessage = '';
  int _currentPage = 0;

  String? userId;

  final isEditMode = false;

  bool _isLoading = false;
  
  List<String> genres = [];
  List<String> selectedGenres = [];

  String? uploadedFileName;
  bool isPhysicalSelected = false;
  bool isDigitalSelected = false;

  File? _coverImageFile;            // Para móvil
  Uint8List? _coverImageWebBytes;  // Para web

  File? _digitalFileMobile;
  Uint8List? _digitalFileWebBytes;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _loadUserId();
  }

  // Función para obtener las categorías
  void _fetchCategories() async {
    List<String> categories = await _categoryController.getCategories();
    setState(() {
      genres = categories;
    });
  }

  // Función para obtener el id del usuario actual
  void _loadUserId() async {
    final id = await AccountController().getCurrentUserId();
    setState(() {
      userId = id;
    });
  }

  // Función para pasar a la página de selección de géneros y resumen
  Future<void> nextPage() async {
    FocusScope.of(context).unfocus(); // Cerrar teclado

    // Esperar un poco antes de navegar
    await Future.delayed(const Duration(milliseconds: 500));

    if (_formKey.currentState?.validate() ?? false) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage = 1;
      });
    }
  }

  // Función para pasar a la página de datos personales desde la selección de géneros
  void prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  // Función que muestra el dialogo de éxito al añadir un nuevo libro
  void _showSuccessDialog() {
    SuccessDialog.show(
      context,
      'Creación Exitosa',
      '¡Tu libro ha sido creado con éxito!',
      () {
        Navigator.pop(context);
        Future.microtask(() {
          if (widget.origin == 'book_details') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailsOwnerView(bookId: widget.bookId!),
              ),
            );
          } else if (widget.origin == 'profile') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OwnerProfileView(userId: userId!),
              ),
            );
          }
        });
      },
    );
  }


  // Método que realiza la función de añadir un nuevo libro
  Future<void> _addBook() async {
    bool hasError = false;

    // Validación de géneros seleccionados
    if (selectedGenres.isEmpty) {
      setState(() {
        _message = "* Seleccione al menos un género asociado";
      });
      hasError = true;
    }

    // Validación de resumen
    String summaryText = _summaryController.text.trim();
    if (summaryText.isEmpty) {
      setState(() {
        _summaryMessage = 'Por favor introduzca un resumen del libro';
      });
      hasError = true;
    } else if (summaryText.length < 30) {
      setState(() {
        _summaryMessage = 'El resumen debe tener al menos 30 caracteres';
      });
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _summaryMessage = '';
      _message = '';
      _isLoading = true;
    });

    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final isbn = _isbnController.text.trim();
    final pagesNumber = int.tryParse(_pagesNumberController.text.trim()) ?? 0;
    final language = _languageController.text.trim();
    final summary = summaryText;

    final List<String> formats = [];
    if (isPhysicalSelected) formats.add('Físico');
    if (isDigitalSelected) formats.add('Digital');

    File? fileToSend = isDigitalSelected ? _digitalFileMobile : null;
    Uint8List? fileBytesToSend = isDigitalSelected ? _digitalFileWebBytes : null;

    final result = await _bookController.addBook(
      title,
      author,
      isbn,
      pagesNumber,
      language,
      formats.join(", "),
      // Pasa el archivo físico o los bytes web:
      kIsWeb ? fileBytesToSend : fileToSend,
      summary,
      selectedGenres.join(", "),
      _coverImageFile ?? _coverImageWebBytes,
    );

    setState(() {
      _isLoading = false;
      _message = result['message'];
    });

    if (result['success']) {
      setState(() {
        _message = '';
        _summaryMessage = '';
      });
      _showSuccessDialog();
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Al tocar fuera del campo de texto, se oculta el teclado
        FocusScope.of(context).unfocus();
      },
      child: Background(
        title: 'Añadir libro',
        onBack: prevPage,
        child: PageNavigation(
          pageController: _pageController,
          currentPage: _currentPage,
          firstPage: _buildBookInfoPage(),
          secondPage: _buildGenreAndSummarySelectionPage(),
        ),
      ),
    );
  }

  // Página de registro: Datos Personales
  Widget _buildBookInfoPage() {
    return BookInfoForm(
      titleController: _titleController,
      authorController: _authorController,
      isbnController: _isbnController,
      pagesNumberController: _pagesNumberController,
      languageController: _languageController,
      formatController: _formatController,
      onNext: nextPage,
      formKey: _formKey,
      initialCoverImageFile: _coverImageFile,
      initialCoverImageWebBytes: _coverImageWebBytes,
      onFileAndFormatChanged: (fileMobile, fileWebBytes, isPhysical, isDigital) {
        setState(() {
          _digitalFileMobile = fileMobile;
          _digitalFileWebBytes = fileWebBytes;
          isPhysicalSelected = isPhysical;
          isDigitalSelected = isDigital;
        });
      },
      onCoverImagePickedMobile: (imageFile) {
        setState(() {
          _coverImageFile = imageFile;
          _coverImageWebBytes = null; // Reseteamos web si se usa mobile
        });
      },
      onCoverImagePickedWeb: (imageBytes) {
        setState(() {
          _coverImageWebBytes = imageBytes;
          _coverImageFile = null; // Reseteamos mobile si se usa web
        });
      },

    );
  }

  // Página de registro: Selección de Géneros y Resumen
  Widget _buildGenreAndSummarySelectionPage() {
    return GenreAndSummarySelectionWidget(
      formKey: _secondFormKey,
      isEditMode: isEditMode,
      genres: genres,
      selectedGenres: selectedGenres,
      summaryError: _summaryMessage,
      genreError: _message,
      onGenreSelected: (genre) {
        setState(() {
          if (selectedGenres.contains(genre)) {
            selectedGenres.remove(genre);
          } else {
            selectedGenres.add(genre);
          }
          if (selectedGenres.isNotEmpty) {
            _message = '';
          }
        });
      },
      onRegister: _addBook,
      summaryController: _summaryController,
      isLoading: _isLoading,
      onSummaryChanged: () {
      setState(() {
        _summaryMessage = '';
      });
    },
    );
  }

}