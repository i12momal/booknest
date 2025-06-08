import 'dart:io';
import 'dart:typed_data';
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/widgets/book_cover_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:booknest/widgets/language_dropdown.dart';
import 'package:booknest/controllers/book_controller.dart';

// Widget para la vista de datos generales del libro durante su edición
class BookInfoFormEdit extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController authorController;
  final TextEditingController isbnController;
  final TextEditingController pagesNumberController;
  final TextEditingController languageController;
  final TextEditingController bookStateController;
  final TextEditingController? formatController;
  final VoidCallback onNext;
  final GlobalKey<FormState> formKey;
  final void Function(bool isPhysical, bool isDigital) onFormatChanged;
  final void Function(File?) onFilePicked;
  final List<String> selectedFormats;
  final int bookId;
  final String? originalTitle;

  // Imagen de portada (movil)
  final File? coverFile;
  // Imagen de portada (Web)
  final Uint8List? coverFileWebBytes;
  // URL de imagen de portada si ya está en el servidor
  final String? coverImageUrl;

  // Callback para cuando se seleccione una portada (movil o Web)
  final void Function(File?)? onCoverPickedMobile;
  final void Function(Uint8List?)? onCoverPickedWeb;

  // Parámetro para saber si estamos en modo de edición
  final bool isEditMode;

  const BookInfoFormEdit({
    super.key,
    required this.titleController,
    required this.authorController,
    required this.isbnController,
    required this.pagesNumberController,
    required this.languageController,
    required this.bookStateController,
    this.formatController,
    required this.onNext,
    required this.formKey,
    required this.onFormatChanged,
    required this.onFilePicked,
    required this.isEditMode,
    required this.coverFile,
    this.coverImageUrl,
    this.selectedFormats = const [],
    required this.bookId,
    this.originalTitle,
    this.coverFileWebBytes,
    this.onCoverPickedMobile,
    this.onCoverPickedWeb
  });

  @override
  State<BookInfoFormEdit> createState() => _BookInfoFormEditState();
}

class _BookInfoFormEditState extends State<BookInfoFormEdit> {
  String? languageErrorMessage;
  String? bookStateErrorMessage;
  String? formatErrorMessage;
  String? coverImageErrorMessage;
  String? fileErrorMessage;
  File? coverImageFile;
  String? ownerId;

  // Variables de estado para los checkboxes
  bool isPhysicalSelected = false;
  bool isDigitalSelected = false;

  String? uploadedFileName;
  bool isUploading = false;
  File? coverImage;

  late final BookController bookController;

  String? _titleValidationMessage;
  late FocusNode _titleFocusNode;

  @override
  void initState() {
    super.initState();
    _titleFocusNode = FocusNode();
    bookController = BookController();
    coverImageFile = widget.coverFile;
    _loadUserId();

    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus) {
        validateTitle(widget.titleController.text);
      }
    });

    // Si estamos en modo edición, cargamos los datos del libro (no actualizamos nada).
    if (widget.isEditMode) {
      // Aquí solo cargamos los datos del libro sin hacer un "update"
      Future.delayed(Duration.zero, () async {
        final bookData = await BookController().getBookById(widget.bookId); 
        if (bookData != null) {
          loadBookData(bookData);
        }
      });
    }
  }

  // Validar isbn
  String? validateISBN(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return 'Por favor ingresa el ISBN del libro';
    } else if (!_isValidISBN(trimmed)) {
      return 'ISBN no válido';
    }
    
    return null; // Si es válido
  }

  bool _isValidISBN(String value) {
    // Verificamos si es ISBN-13
    final isbn13RegEx = RegExp(r'^\d{13}$');
    
    // Verificamos si es ISBN-10
    final isbn10RegEx = RegExp(r'^\d{9}[\dX]$');
    
    return isbn13RegEx.hasMatch(value) || isbn10RegEx.hasMatch(value);
  }

  // Cargar los datos del libro
  void loadBookData(Book book) {
    final formatoList = book.format.toLowerCase().split(',').map((e) => e.trim()).toList();
    final fileUrl = book.file;

    String? fileName;

    if (fileUrl != null && fileUrl.isNotEmpty) {
      final rawName = Uri.decodeFull(fileUrl.split('/').last);
      print("Raw name extracted: $rawName");

      final dotIndex = rawName.lastIndexOf('.');
      if (dotIndex != -1) {
        final nameParts = rawName.substring(0, dotIndex).split('_');

        if (nameParts.length > 2) {
          final cleanedName = nameParts.sublist(0, nameParts.length - 2).join('_');
          final extension = rawName.substring(dotIndex);
          fileName = "$cleanedName$extension";
        } else {
          fileName = rawName;
        }
      } else {
        fileName = rawName;
      }

      print("File name extracted: $fileName");
    }

    setState(() {
      isPhysicalSelected = formatoList.contains('físico');
      isDigitalSelected = formatoList.contains('digital');
      if (fileUrl != null) {
        widget.onFilePicked(File(fileUrl));
        uploadedFileName = fileName;  // Asigna el nombre del archivo
        print("Uploaded file name set: $uploadedFileName"); // Verificar que el nombre se asigna correctamente
      }

      if (widget.coverImageUrl != null) {
        // Verifica si coverImageUrl es una URL
        if (widget.coverImageUrl!.startsWith('http') || widget.coverImageUrl!.startsWith('https')) {
          // Es una URL, se debe usar NetworkImage
          coverImage = null;
        } else {
          // Es un archivo local, se debe usar FileImage
          coverImage = File(widget.coverImageUrl!);
        }
      }
    });
  }

  // Obtener el id del usuario actual
  void _loadUserId() async {
    final id = await AccountController().getCurrentUserId();
    setState(() {
      ownerId = id;
    });
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    super.dispose();
  }

  // Validar el título
  Future<void> validateTitle(String title) async {
    final trimmed = title.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _titleValidationMessage = 'Por favor ingresa el título del libro';
      });
    } else if (trimmed == widget.originalTitle) {
        setState(() {
          _titleValidationMessage = null;
        });
      }else{
        bool titleExists = await BookController().checkTitleExists(trimmed, ownerId!);
        setState(() {
          _titleValidationMessage = titleExists ? 'Ya tiene un libro con este título' : null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Row(
              children: [
                Text(
                  'Datos Generales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Icon(Icons.menu_book),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF687CFF), Color(0xFF2E3C94)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.29, 0.55],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF112363),
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Título', Icons.class_outlined, widget.titleController,
                    validator: (value) {
                        return _titleValidationMessage;
                      },
                      onChanged: (value) {
                        validateTitle(value);
                      },
                      focusNode: _titleFocusNode,
                    ),
                    _buildTextField('Autor', Icons.person, widget.authorController,
                    validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Por favor ingresa el autor del libro';
                        } 
                        return null;
                      },),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ISBN',
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        CustomTextField(
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Por favor ingresa el ISBN del libro';
                            } 
                            // Verificar si el ISBN es válido 
                            else if (!_isValidISBN(trimmed)) {
                              return 'ISBN no válido';
                            }
                            return null;
                          }, 
                          icon: Icons.menu,
                          hint: '123456789X ó 9781234567897',
                          controller: widget.isbnController,
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                    _buildTextField('Número de páginas', Icons.insert_drive_file_outlined , widget.pagesNumberController,
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Por favor ingresa el número de páginas';
                      }
                      
                      final numericRegEx = RegExp(r'^\d+$');
                      if (!numericRegEx.hasMatch(trimmed)) {
                        return 'Debe ser un número válido';
                      }
                      return null; 
                    },),
                    
                    // Etiqueta y dropdown de idioma
                    const Text(
                      'Idioma',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    LanguageDropdown(
                      controller: widget.languageController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, seleccione un idioma';
                        }
                        return null;
                      },
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue.isNotEmpty) {
                          setState(() {
                            languageErrorMessage = null;
                          });
                          widget.languageController.text = newValue;
                          widget.formKey.currentState?.validate();
                        }
                      },
                    ),
                    if (languageErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          languageErrorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    
                    const SizedBox(height: 15),

                    BookCoverPickerWidget(
                      initialCoverImage: widget.coverFile,
                      initialCoverImageWebBytes: widget.coverFileWebBytes,
                      coverImageUrl: widget.coverImageUrl,
                      onCoverImagePickedMobile: widget.onCoverPickedMobile,
                      onCoverImagePickedWeb: widget.onCoverPickedWeb,
                    ),

            
                    const SizedBox(height: 15),
                    const Text(
                      'Formato',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const SizedBox(width: 25),
                        Checkbox(
                          value: widget.selectedFormats.contains('Físico'),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value ?? false) {
                                widget.selectedFormats.add('Físico');
                              } else {
                                widget.selectedFormats.remove('Físico');
                              }
                            });
                            widget.onFormatChanged(
                              widget.selectedFormats.contains('Físico'),
                              widget.selectedFormats.contains('Digital'),
                            );
                              _checkFormatSelection();
                          },
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        const Text('Físico', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 35),
                        Checkbox(
                          value: widget.selectedFormats.contains('Digital'),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value ?? false) {
                                widget.selectedFormats.add('Digital');
                              } else {
                                widget.selectedFormats.remove('Digital');
                              }
                            });
                            widget.onFormatChanged(
                              widget.selectedFormats.contains('Físico'),
                              widget.selectedFormats.contains('Digital'),
                            );
                              _checkFormatSelection();
                          },
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        const Text('Digital', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),


                    // Mostrar el mensaje de error debajo del campo de formato si ningún formato ha sido seleccionado
                    if (formatErrorMessage != null && formatErrorMessage!.isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          formatErrorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    if(widget.selectedFormats.contains('Digital'))...{
                      const Text(
                        'Archivo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: BookController().isUploading
                        ? const Center (child: CircularProgressIndicator())
                        : OutlinedButton(
                          onPressed: _pickFile,
                          
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.black, width: 2),
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isUploading)...{
                                const Expanded(
                                  child: Center(
                                    child: SizedBox(
                                      width: 20, // Ajusta el tamaño del loader
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                )
                              }else...{
                                Expanded(
                                  child: Text(
                                    uploadedFileName ?? 'Seleccione un archivo...',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromRGBO(124, 123, 123, 1),
                                    ),
                                  ),
                                ),
                              },
                              const Icon(Icons.attach_file, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      if (fileErrorMessage != null) ...{
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            fileErrorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      },


                    }else...[], 

                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Resetear errores
                          setState(() {
                            coverImageErrorMessage = null;
                            formatErrorMessage = null;
                            fileErrorMessage = null;
                            languageErrorMessage = null;
                          });

                          await Future.wait([
                            validateTitle(widget.titleController.text)
                          ]);

                          // Validar formulario
                          final isFormValid = widget.formKey.currentState?.validate() ?? false;
                          print("Formulario válido: $isFormValid");

                          // Validar portada
                          bool hasCoverImage = coverImageFile != null || widget.coverImageUrl != null;
                          if (!hasCoverImage) {
                            coverImageErrorMessage = 'Por favor selecciona una imagen de portada';
                          }
                          print("Validación de portada: $hasCoverImage");

                          // Validar formato
                          bool hasFormat = widget.selectedFormats.isNotEmpty;
                          if (!hasFormat) {
                            formatErrorMessage = '* Seleccione al menos un formato';
                          }
                          print("Validación de formato: $hasFormat");

                          // Validar archivo digital 
                          bool isDigitalSelected = widget.selectedFormats.contains('Digital');
                          bool hasFileIfDigital = isDigitalSelected && (uploadedFileName == null || uploadedFileName!.isEmpty);
                          if (hasFileIfDigital) {
                            fileErrorMessage = 'Es necesario un archivo para el formato digital';
                          }
                          print("Archivo digital: $hasFileIfDigital");

                          // Reflejar todos los errores en pantalla
                          setState(() {});

                          // Avanzar solo si todo está válido
                          if (isFormValid && hasCoverImage && hasFormat && !hasFileIfDigital && _titleValidationMessage == null) {
                            print("Formulario validado. Avanzando al siguiente paso.");
                            widget.onNext();
                          } else {
                            print("No se pudo avanzar. Revisando errores:");
                            print("Error portada: $coverImageErrorMessage");
                            print("Error formato: $formatErrorMessage");
                            print("Error archivo: $fileErrorMessage");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAD0000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(color: Colors.white, width: 3),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        ),
                        child: const Text(
                          "Siguiente",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para el diseño de los campos a ingresar
  Widget _buildTextField(String label, IconData? icon, TextEditingController controller, {String? Function(String?)? validator, ValueChanged<String>? onChanged, FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        CustomTextField(
          validator:validator,
          icon: icon,
          hint: '',
          controller: controller,
          onChanged: onChanged,
          focusNode: focusNode,
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  // Función que verifica si al menos un formato ha sido seleccionado
  void _checkFormatSelection() {
    if (widget.selectedFormats.isEmpty) {
      setState(() {
        formatErrorMessage = 'Seleccione al menos un formato';
      });
    } else {
      setState(() {
        formatErrorMessage = null;
      });
    }
    print("Formatos seleccionados: ${widget.selectedFormats}");

  }

  // Función para seleccionar una imagen o archivo
  void _pickFile() async {
    setState(() {
      isUploading = true;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      // Validar que el archivo tenga extensión .pdf
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        setState(() {
          uploadedFileName = null;
          isUploading = false;
          fileErrorMessage = 'El archivo debe ser un PDF';
        });

        widget.onFilePicked(null);
        return;
      }

      setState(() {
        uploadedFileName = fileName;
        isUploading = false;
        fileErrorMessage = null;
      });

      widget.onFilePicked(File(filePath));
    } else {
      setState(() {
        isUploading = false;
      });

      widget.onFilePicked(null);
    }
  }

}
