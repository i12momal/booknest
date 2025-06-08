import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Widget para la subida de la imagen de portada de un libro
class BookCoverPickerWidget extends StatefulWidget {
  final File? initialCoverImage;
  final Uint8List? initialCoverImageWebBytes;
  final String? coverImageUrl;
  final ValueChanged<File?>? onCoverImagePickedMobile;
  final ValueChanged<Uint8List?>? onCoverImagePickedWeb;

  const BookCoverPickerWidget({
    super.key,
    this.initialCoverImage,
    this.initialCoverImageWebBytes,
    this.coverImageUrl,
    this.onCoverImagePickedMobile,
    this.onCoverImagePickedWeb,
  });

  @override
  State<BookCoverPickerWidget> createState() => _BookCoverPickerWidgetState();
}

class _BookCoverPickerWidgetState extends State<BookCoverPickerWidget> {
  File? _coverImageFile;
  Uint8List? _coverImageBytesWeb;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _coverImageBytesWeb = widget.initialCoverImageWebBytes;
    } else {
      _coverImageFile = widget.initialCoverImage;
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _coverImageBytesWeb = bytes;
        });
        if (widget.onCoverImagePickedWeb != null) {
          widget.onCoverImagePickedWeb!(bytes);
        }
      } else {
        final file = File(pickedFile.path);
        setState(() {
          _coverImageFile = file;
        });
        if (widget.onCoverImagePickedMobile != null) {
          widget.onCoverImagePickedMobile!(file);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (kIsWeb) {
      if (_coverImageBytesWeb != null) {
        imageProvider = MemoryImage(_coverImageBytesWeb!);
      } else if (widget.coverImageUrl != null && widget.coverImageUrl!.startsWith('http')) {
        imageProvider = NetworkImage(widget.coverImageUrl!);
      } else {
        imageProvider = const AssetImage('assets/images/portada.png');
      }
    } else {
      if (_coverImageFile != null) {
        imageProvider = FileImage(_coverImageFile!);
      } else if (widget.coverImageUrl != null && widget.coverImageUrl!.startsWith('http')) {
        imageProvider = NetworkImage(widget.coverImageUrl!);
      } else {
        imageProvider = const AssetImage('assets/images/portada.png');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Portada',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );

  }
}
