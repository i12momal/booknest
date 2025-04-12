import 'dart:io';
import 'package:booknest/entities/models/book_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:booknest/widgets/language_dropdown.dart';
import 'package:booknest/widgets/bookstate_dropdown.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:image_picker/image_picker.dart';

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
  final void Function(File?) onCoverPicked; 
  final List<String> selectedFormats;

  // Nuevo parámetro para saber si estamos en modo de edición
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
    required this.onCoverPicked,
    required this.isEditMode,
    this.selectedFormats = const [],
  });

  @override
  State<BookInfoFormEdit> createState() => _BookInfoFormEditState();
}

class _BookInfoFormEditState extends State<BookInfoFormEdit> {
  String? languageErrorMessage;
  String? bookStateErrorMessage;
  String? formatErrorMessage;

  // Variables de estado para los checkboxes
  bool isPhysicalSelected = false;
  bool isDigitalSelected = false;

  String? uploadedFileName;
  bool isUploading = false;
  File? coverImage;

  late final BookController bookController;

  @override
  void initState() {
    super.initState();
    bookController = BookController();

    // Si estamos en modo edición, cargamos los datos del libro.
    if (widget.isEditMode) {
      // Simula una carga asincrónica
      Future.delayed(Duration.zero, () async {
        final bookData = await BookController().getBookById(1); 
        if (bookData != null) {
          loadBookData(bookData);
        }
      });
    }
  }

  void loadBookData(Book book) {
    final formatoList = book.format.toLowerCase().split(',').map((e) => e.trim()).toList();
    final fileUrl = book.file;

    String? fileName;

    if (fileUrl != null) {
      final rawName = Uri.decodeFull(fileUrl.split('/').last); // Extrae el nombre del archivo
      print("Raw name extracted: $rawName");

      // Verifica si el nombre contiene un guion bajo (usualmente se usa para separar el nombre y el ID)
      final lastUnderscore = rawName.lastIndexOf('_');
      final dotIndex = rawName.lastIndexOf('.');

      if (lastUnderscore != -1 && dotIndex > lastUnderscore) {
        // Extrae desde el inicio hasta el último '_', y agrega la extensión
        fileName = rawName.substring(0, lastUnderscore) + rawName.substring(dotIndex);
      } else {
        fileName = rawName;
      }

      print("File name extracted: $fileName"); // Verificar que el nombre se extrae correctamente
    }

    setState(() {
      isPhysicalSelected = formatoList.contains('físico');
      isDigitalSelected = formatoList.contains('digital');
      if (fileUrl != null) {
        widget.onFilePicked(File(fileUrl));
        uploadedFileName = fileName;  // Asigna el nombre del archivo
        print("Uploaded file name set: $uploadedFileName"); // Verificar que el nombre se asigna correctamente
      }
    });
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
                    _buildTextField('Título', Icons.class_outlined, widget.titleController),
                    _buildTextField('Autor', Icons.person, widget.authorController),
                    _buildTextField('ISBN', Icons.menu, widget.isbnController),
                    _buildTextField('Número de páginas', Icons.insert_drive_file_outlined , widget.pagesNumberController),
                    
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

                    if(widget.isEditMode == true )...[
                      const Text(
                        'Estado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      BookStateDropdown(
                        controller: widget.bookStateController,
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue.isNotEmpty) {
                            setState(() {
                              bookStateErrorMessage = null;
                            });
                            widget.bookStateController.text = newValue;
                            widget.formKey.currentState?.validate();
                          }
                        },
                      ),
                      if (bookStateErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            bookStateErrorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      
                      const SizedBox(height: 15),
                    ]else...[],

                    const SizedBox(height: 15),
                    const Text(
                      'Portada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    OutlinedButton(
                      onPressed: _pickCoverImage, // Acción para seleccionar la portada
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
                          if (coverImage != null) ...[
                            Image.file(
                              coverImage!, 
                              width: 40, 
                              height: 40, 
                              fit: BoxFit.cover,
                            ),
                          ] else ...[
                            const Text(
                              'Seleccionar portada...',
                              style: TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                          ],
                          const Icon(Icons.image, color: Colors.grey),
                        ],
                      ),
                    ),





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
                    }else...[], 

                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () {
                          // Verificar que al menos un formato esté seleccionado
                          if (widget.selectedFormats.isEmpty) {
                            setState(() {
                              formatErrorMessage = 'Seleccione al menos un formato'; // Mostrar mensaje de error
                            });
                            return; // Evita que se ejecute cualquier otra cosa si no se seleccionó ningún formato
                          } else {
                            setState(() {
                              formatErrorMessage = null; // Limpiar mensaje de error si hay formatos seleccionados
                            });
                          }
                          widget.onNext();
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

  Widget _buildTextField(String label, IconData? icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        CustomTextField(
          icon: icon,
          hint: '',
          controller: controller,
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
  }

  Future<void> _pickCoverImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      // Aquí se pasa el archivo de imagen a la función onCoverPicked para actualizar el estado
      widget.onCoverPicked(File(pickedImage.path));
    }
  }


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

      setState(() {
        uploadedFileName = fileName;
        isUploading = false;
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
