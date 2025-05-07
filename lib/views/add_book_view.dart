import 'dart:io';
import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/page_navigation.dart';
import 'package:booknest/widgets/book_info_form_add.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:booknest/widgets/genre_and_summary_selection.dart';

// Vista para la acción de Añadir un nuevo libro
class AddBookView extends StatefulWidget{
  const AddBookView ({super.key});

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

  final isEditMode = false;

  bool _isLoading = false;
  
  List<String> genres = [];
  List<String> selectedGenres = [];

  String? uploadedFileName;
  bool isPhysicalSelected = false;
  bool isDigitalSelected = false;

  File? coverImage;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Función para obtener las categorías
  void _fetchCategories() async {
    List<String> categories = await _categoryController.getCategories();
    setState(() {
      genres = categories;
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
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() {
      _currentPage = 0;
    });
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

    // Si hay errores, salimos del método
    if (hasError) return;

    // Limpiar mensajes de error y empezar a cargar
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

    File? file;
    if (isDigitalSelected && uploadedFileName?.isNotEmpty == true) {
      file = File(uploadedFileName!);
    }

    final result = await _bookController.addBook(
      title, author, isbn, pagesNumber, language, formats.join(", "),
      file, summary, selectedGenres.join(", "), coverImage
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


  // Función que muestra el dialogo de éxito al añadir un nuevo libro
  void _showSuccessDialog() {
    SuccessDialog.show(
      context,
      'Creación Exitosa', 
      '¡Tu libro ha sido creado con éxito!',
      () {
        Navigator.pop(context);

        // Redirigir a la pantalla de inicio de sesión después de que el usuario acepte
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
      coverImage: coverImage,
      formKey: _formKey,
      onFileAndFormatChanged: (file, isPhysical, isDigital) {
        setState(() {
          uploadedFileName = file;
          isPhysicalSelected = isPhysical;
          isDigitalSelected = isDigital;
      });
      },
      onCoverImageChanged: (image) {
        setState(() {
          coverImage = image; 
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