import 'dart:io';
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/widgets/book_info_form.dart';
import 'package:booknest/widgets/genre_and_summary_selection.dart';
import 'package:flutter/material.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/page_navigation.dart';
import 'package:booknest/widgets/success_dialog.dart';

// Vista para la acción de Edición de Datos de Usuario 
class EditBookView extends StatefulWidget {
  final int bookId;
  const EditBookView({super.key, required this.bookId});

  @override
  State<EditBookView> createState() => _EditBookViewState();
}

class _EditBookViewState extends State<EditBookView> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _pagesNumberController = TextEditingController();
  final _languageController = TextEditingController();
  final _summaryController = TextEditingController();
  final _stateController = TextEditingController();
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();

  final PageController _pageController = PageController();
  final BookController _bookController = BookController();
  final CategoriesController _categoryController = CategoriesController();

  final bool isEditMode = true;
  bool _isLoading = false;
  String _message = '';
  int _currentPage = 0;
  
  List<String> genres = [];
  List<String> selectedGenres = [];
  String? currentImageUrl;

  List<String> selectedFormat = [];

  String? uploadedFileName;
  bool isPhysicalSelected = false;
  bool isDigitalSelected = false;

  @override
  void initState() {
    super.initState();
    _fetchBookData();
    _fetchCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _pagesNumberController.dispose();
    _languageController.dispose();
    _summaryController.dispose();
    _stateController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Función que maneja la imagen seleccionada
  void _handleImagePicked(File? image) {
    setState(() {
      _imageFile = image;
    });
  }

  // Función para cargar datos del libro
  Future<void> _fetchBookData() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    // Verifica si el usuario está autenticado
    final userId = await AccountController().getCurrentUserId();
    if (userId == null) {
      setState(() {
        _message = 'No se ha iniciado sesión';
        _isLoading = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
      return;
    }

    try {
      final Book? bookData = await _bookController.getBookById(widget.bookId);
      if (bookData != null) {
        print("Libro obtenido correctamente: ${bookData.title}");
        setState(() {
          _titleController.text = bookData.title;
          _authorController.text = bookData.author;
          _isbnController.text = bookData.isbn;
          _pagesNumberController.text = bookData.pagesNumber.toString();
          _languageController.text = bookData.language;
          _summaryController.text = bookData.summary;
          _stateController.text = bookData.state;
          
          // Cargar géneros seleccionados
        if (bookData.categories != null && bookData.categories.isNotEmpty) {
          selectedGenres = bookData.categories.split(',').map((genre) => genre.trim()).toList();
        }

          currentImageUrl = bookData.file;
          
          // Inicializamos los formatos seleccionados
          selectedFormat.clear();
          if (bookData.format.contains('Físico')) {
            selectedFormat.add('Físico');
          }
          if (bookData.format.contains('Digital')) {
            selectedFormat.add('Digital');
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _message = 'No se encontró la información del libro. Por favor, intente nuevamente.';
          _isLoading = false;
        });
      }
    } catch (e) {
       print("Error al obtener los datos del libro: $e");
      setState(() {
        _message = 'Error al cargar los datos del libro. Por favor, intente nuevamente.';
        _isLoading = false;
      });
    }
  }

  // Función para obtener las categorías
  void _fetchCategories() async {
    try {
      List<String> categories = await _categoryController.getCategories();
      setState(() {
        genres = categories;
      });
    } catch (e) {
      setState(() {
        _message = 'Error al cargar las categorías';
      });
    }
  }

  // Función para pasar a la página de selección de géneros desde la página de datos personales
  Future<void> nextPage() async {
    FocusScope.of(context).unfocus();
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
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() {
      _currentPage = 0;
    });
  }

  // Método para actualizar el libro
  Future<void> _updateBook() async {
    if (selectedGenres.isEmpty) {
      setState(() {
        _message = "* Seleccione al menos un género asociado";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final title = _titleController.text.trim();
      final author = _authorController.text.trim();
      final isbn = _isbnController.text.trim();
      final pagesNumber = int.tryParse(_pagesNumberController.text.trim()) ?? 0;
      final language = _languageController.text.trim();
      final summary = _summaryController.text.trim();
      final state = _stateController.text.trim();

      // Mantener la imagen actual si no se ha seleccionado una nueva
      final imageUrl = _imageFile ?? currentImageUrl ?? '';

      final userId = AccountController().getCurrentUserId();

      final result = await _bookController.editBook(
        widget.bookId,
        title,
        author,
        isbn,
        pagesNumber,
        language,
        selectedFormat.join(", "),
        _imageFile,
        summary,
        selectedGenres.join(", "),
        state,
        userId as String,
        userId as String
      );

      if (result['success']) {
        _showSuccessDialog();
      } else {
        setState(() {
          _message = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error al actualizar los datos del libro';
        _isLoading = false;
      });
    }
  }

  // Función que muestra el dialogo de éxito al actualizar un usuario
  void _showSuccessDialog() {
    SuccessDialog.show(
      context,
      'Actualización Exitosa', 
      'Los datos del libro han sido actualizados correctamente!',
      () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Al tocar fuera del campo de texto, se oculta el teclado
        FocusScope.of(context).unfocus();
      },
      child: Background(
        title: 'Editar libro',
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
      isEditMode: isEditMode,
      titleController: _titleController,
      authorController: _authorController,
      isbnController: _isbnController,
      pagesNumberController: _pagesNumberController,
      languageController: _languageController,
      selectedFormats: selectedFormat,
      onNext: nextPage,
      formKey: _formKey,
      onFileAndFormatChanged: (file, isPhysical, isDigital) {
        setState(() {
          uploadedFileName = file;
          isPhysicalSelected = isPhysical;
          isDigitalSelected = isDigital;
        });
        // Limpiar la lista de formatos seleccionados
        selectedFormat.clear();

        // Agregar los formatos seleccionados
        if (isPhysical) {
          selectedFormat.add('Físico');
        }
        if (isDigital) {
          selectedFormat.add('Digital');
        }
      },
    );
  }

  // Página de registro: Selección de Géneros y Resumen
  Widget _buildGenreAndSummarySelectionPage() {
    return GenreAndSummarySelectionWidget(
      isEditMode: isEditMode,
      genres: genres,
      selectedGenres: selectedGenres,
      message: _message,
      onGenreSelected: (genre) {
        setState(() {
          if (selectedGenres.contains(genre)) {
            selectedGenres.remove(genre);
          } else {
            selectedGenres.add(genre);
          }
          if (selectedGenres.isNotEmpty) {
            _message = '';  // Limpiar mensaje si ya hay géneros seleccionados
          }
        });
      },
      onRegister: _updateBook,
      summaryController: _summaryController,
    );
  }
}
