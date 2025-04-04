import 'package:booknest/entities/models/user_session.dart';
import 'package:booknest/services/account_service.dart';
import 'package:flutter/material.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:booknest/widgets/language_dropdown.dart';
import 'package:booknest/controllers/book_controller.dart';

class BookInfoForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController authorController;
  final TextEditingController isbnController;
  final TextEditingController pagesNumberController;
  final TextEditingController languageController;
  final TextEditingController formatController;
  final VoidCallback onNext;
  final GlobalKey<FormState> formKey;

  final Function(String? file, bool isPhysical, bool isDigital) onFileAndFormatChanged;

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
  });

  @override
  State<BookInfoForm> createState() => _BookInfoFormState();
}

class _BookInfoFormState extends State<BookInfoForm> {
  String? languageErrorMessage;
  String? formatErrorMessage;

  // Variables de estado para los checkboxes
  bool isPhysicalSelected = false;
  bool isDigitalSelected = false;

  String? uploadedFileName;
  bool isUploading = false;

  late final BookController bookController;

  @override
  void initState() {
    super.initState();
    bookController = BookController();
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
                              widget.onFileAndFormatChanged(uploadedFileName, isPhysicalSelected, isDigitalSelected);
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
                              widget.onFileAndFormatChanged(uploadedFileName, isPhysicalSelected, isDigitalSelected);
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
                          style: const TextStyle(color: Colors.red),
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
                        child: BookController().isUploading
                        ? const Center (child: CircularProgressIndicator())
                        : OutlinedButton(
                          onPressed: _pickAndUploadFile,
                          
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
                          // Verificamos si al menos uno de los formatos está seleccionado
                          if (!isPhysicalSelected && !isDigitalSelected) {
                            setState(() {
                              _checkFormatSelection();
                            });
                            return;
                          } else {
                            setState(() {
                              formatErrorMessage = null;
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
    setState(() {
      if (!isPhysicalSelected && !isDigitalSelected) {
        formatErrorMessage = 'Seleccione al menos un formato';
      } else {
        formatErrorMessage = null;
      }
    });
  }

  void _pickAndUploadFile() async {
    setState(() {
      isUploading = true;
    });

    // Obtener el título del libro y el UID del usuario
    String bookTitle = widget.titleController.text.trim();
    final userId = await UserSession.getUserId();

    // Llamar a la función y pasar los parámetros
    String? fileName = await bookController.pickAndUploadFile(bookTitle, userId);

    setState(() {
      uploadedFileName = fileName ?? "Error al subir archivo";
      isUploading = false;
      widget.onFileAndFormatChanged(uploadedFileName, isPhysicalSelected, isDigitalSelected);
    });
  }



}
