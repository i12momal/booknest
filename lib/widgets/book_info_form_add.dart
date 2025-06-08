import 'dart:io';
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/widgets/book_cover_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:booknest/widgets/language_dropdown.dart';
import 'package:booknest/controllers/book_controller.dart';

// Widget para la vista de datos generales del libro durante su creación
class BookInfoForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController authorController;
  final TextEditingController isbnController;
  final TextEditingController pagesNumberController;
  final TextEditingController languageController;
  final TextEditingController formatController;
  final VoidCallback onNext;
  final GlobalKey<FormState> formKey;
  final File? initialCoverImageFile;
  final Uint8List? initialCoverImageWebBytes;
  final ValueChanged<File?>? onCoverImagePickedMobile;
  final ValueChanged<Uint8List?>? onCoverImagePickedWeb;


  final Function(File? fileMobile, Uint8List? fileWebBytes, bool isPhysical, bool isDigital) onFileAndFormatChanged;

  const BookInfoForm({
    super.key,
    required this.titleController,
    required this.authorController,
    required this.isbnController,
    required this.pagesNumberController,
    required this.languageController,
    required this.formatController,
    required this.onNext,
    required this.formKey,
    required this.onFileAndFormatChanged,

    this.initialCoverImageFile,
    this.initialCoverImageWebBytes,
    this.onCoverImagePickedMobile,
    this.onCoverImagePickedWeb,
  });

  @override
  State<BookInfoForm> createState() => _BookInfoFormState();
}

class _BookInfoFormState extends State<BookInfoForm> {
  String? languageErrorMessage;
  String? formatErrorMessage;
  String? _titleValidationMessage;
  late FocusNode _titleFocusNode;

  // Variables de estado para los checkboxes
  bool isPhysicalSelected = false;
  bool isDigitalSelected = false;

  File? _digitalFileMobile;
  Uint8List? _digitalFileWebBytes;

  String? uploadedFileName;
  bool isUploading = false;

  late final BookController bookController;
  File? _coverImageFile;
  Uint8List? _coverImageWebBytes;


  String? coverImageErrorMessage;
  String? fileErrorMessage;

  String? ownerId;


  @override
  void initState() {
    super.initState();
    _titleFocusNode = FocusNode();
    bookController = BookController();
    _coverImageFile = widget.initialCoverImageFile;
    _coverImageWebBytes = widget.initialCoverImageWebBytes;
    _loadUserId();

    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus) {
        validateTitle(widget.titleController.text);
      }
    });
  }

  void _onCoverImagePickedMobile(File? file) {
    setState(() {
      _coverImageFile = file;
      _coverImageWebBytes = null;
      coverImageErrorMessage = null;
    });
    widget.onCoverImagePickedMobile?.call(file);
  }

  void _onCoverImagePickedWeb(Uint8List? bytes) {
    setState(() {
      _coverImageWebBytes = bytes;
      _coverImageFile = null;
      coverImageErrorMessage = null;
    });
    widget.onCoverImagePickedWeb?.call(bytes);
  }


  // Función para obtener el id del usuario actual
  void _loadUserId() async {
    final id = await AccountController().getCurrentUserId();
    setState(() {
      ownerId = id;
    });
  }

  // Método para validar el isbn
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

  // Método para validar el título
  Future<void> validateTitle(String title) async {
    final trimmed = title.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _titleValidationMessage = 'Por favor ingresa el título del libro';
      });
    } else {
        bool titleExists = await BookController().checkTitleExists(trimmed, ownerId!);
        setState(() {
          _titleValidationMessage = titleExists ? 'Ya tiene un libro con este título' : null;
        });
    }
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    super.dispose();
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
                    _buildTextField(
                      'Título', 
                      Icons.class_outlined, 
                      widget.titleController,
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

                    BookCoverPickerWidget(
                      initialCoverImage: _coverImageFile,
                      initialCoverImageWebBytes: _coverImageWebBytes,
                      onCoverImagePickedMobile: _onCoverImagePickedMobile,
                      onCoverImagePickedWeb: _onCoverImagePickedWeb,
                    ),
                    if (coverImageErrorMessage != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        coverImageErrorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    
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
                          value: isPhysicalSelected, 
                          onChanged: (bool? value) {
                            setState(() {
                              isPhysicalSelected = value ?? false;
                              _checkFormatSelection();
                              if (!isDigitalSelected) {
                                // Si deselecciona digital, limpiar archivo
                                uploadedFileName = null;
                                _digitalFileMobile = null;
                                _digitalFileWebBytes = null;
                              }
                               widget.onFileAndFormatChanged(_digitalFileMobile, _digitalFileWebBytes, isPhysicalSelected, isDigitalSelected);
                            });
                          }, 
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        const Text('Físico', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 35),
                        Checkbox(
                          value: isDigitalSelected, 
                          onChanged: (bool? value) {
                            setState(() {
                              isDigitalSelected = value ?? false;
                              _checkFormatSelection();
                              if (!isDigitalSelected) {
                                // Si deselecciona digital, limpiar archivo
                                uploadedFileName = null;
                                _digitalFileMobile = null;
                                _digitalFileWebBytes = null;
                              }
                              widget.onFileAndFormatChanged(_digitalFileMobile, _digitalFileWebBytes, isPhysicalSelected, isDigitalSelected);

                            });
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
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),


                    if(isDigitalSelected)...{
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
                        child: isUploading
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
                                      width: 20,
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
                      if (isDigitalSelected && fileErrorMessage != null) ...{
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

                          // Validar portada
                          bool hasCoverImage = _coverImageFile != null || _coverImageWebBytes != null;
                          if (!hasCoverImage) {
                            coverImageErrorMessage = 'Por favor selecciona una imagen de portada';
                          }

                          // Validar formato
                          bool hasFormat = isPhysicalSelected || isDigitalSelected;
                          if (!hasFormat) {
                            formatErrorMessage = 'Seleccione al menos un formato';
                          }

                          // Validar archivo digital
                          bool hasFileIfDigital = !(isDigitalSelected && uploadedFileName == null);
                          if (!hasFileIfDigital) {
                            fileErrorMessage = 'Sube un archivo para el formato digital';
                          }

                          // Reflejar todos los errores en pantalla
                          setState(() {});

                          // Avanzar solo si todo está válido
                          if (isFormValid && hasCoverImage && hasFormat && hasFileIfDigital && _titleValidationMessage == null) {
                            widget.onNext();
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
          validator: validator, 
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
    setState(() {
      if (!isPhysicalSelected && !isDigitalSelected) {
        formatErrorMessage = 'Seleccione al menos un formato';
      } else {
        formatErrorMessage = null;
      }
    });
  }

  // Función para seleccionar un archivo
  void _pickFile() async {
    setState(() {
      isUploading = true;
      fileErrorMessage = null;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      final platformFile = result.files.single;
      final fileName = platformFile.name;

      if (!fileName.toLowerCase().endsWith('.pdf')) {
        setState(() {
          isUploading = false;
          uploadedFileName = null;
          _digitalFileMobile = null;
          _digitalFileWebBytes = null;
          fileErrorMessage = 'El archivo debe ser un PDF';
        });
        return;
      }

      if (kIsWeb && platformFile.bytes != null) {
        _digitalFileWebBytes = platformFile.bytes;
        _digitalFileMobile = null;
      } else if (platformFile.path != null) {
        _digitalFileMobile = File(platformFile.path!);
        _digitalFileWebBytes = null;
      } else {
        setState(() {
          isUploading = false;
          uploadedFileName = null;
          _digitalFileMobile = null;
          _digitalFileWebBytes = null;
          fileErrorMessage = 'No se pudo cargar el archivo';
        });
        return;
      }

      setState(() {
        uploadedFileName = fileName;
        isUploading = false;
        fileErrorMessage = null;
      });

      // Avisar al padre con el archivo correcto según plataforma
      widget.onFileAndFormatChanged(
      _digitalFileMobile,
      _digitalFileWebBytes,
      isPhysicalSelected,
      isDigitalSelected,
    );

    } else {
      setState(() {
        isUploading = false;
        uploadedFileName = null;
        _digitalFileMobile = null;
        _digitalFileWebBytes = null;
        fileErrorMessage = null;
      });
    }
  }

}