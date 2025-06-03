import 'package:booknest/controllers/loan_controller.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// Vista para la acción de Leer un libro
class BookReaderView extends StatefulWidget {
  final String url;
  final int initialPage;
  final String userId;
  final int bookId;
  final String bookTitle;

  const BookReaderView({
    super.key,
    required this.url,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    this.initialPage = 0,
  });

  @override
  State<BookReaderView> createState() => _BookReaderViewState();
}

class _BookReaderViewState extends State<BookReaderView> {
  late PdfViewerController _pdfViewerController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _currentPage = widget.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF112363), Color(0xFF2140AF)],
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              stops: [0.42, 0.74],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              widget.bookTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark, color: Color(0xFF700101),),
                onPressed: () {
                  LoanController().saveCurrentPageProgress(
                    widget.userId,
                    widget.bookId,
                    _currentPage,
                  );
                  Navigator.pop(context, _currentPage);
                },
              ),
            ],
          ),
        ),
      ),
      body: SfPdfViewer.network(
        widget.url,
        controller: _pdfViewerController,
        onPageChanged: (details) {
          setState(() {
            _currentPage = details.newPageNumber;
          });
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Recuperar el progreso de la página guardada
      int? savedPage = await LoanController().getSavedPageProgress(widget.userId, widget.bookId);
      
      if (savedPage != null) {
        setState(() {
          _currentPage = savedPage;
        });
      }
      
      // Asegurarse de que el PDF se mueva a la página correcta al abrir
      _pdfViewerController.jumpToPage(_currentPage);
    });
  }
  
}
