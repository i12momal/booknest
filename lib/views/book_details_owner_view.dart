import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/widgets/background.dart';
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
  final _controller = BookController();

  @override
  void initState() {
    super.initState();
    _bookFuture = _controller.getBookById(widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Book?>(
      future: _bookFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(body: Center(child: Text("Error cargando el libro")));
        }

        final book = snapshot.data!;
        return Background(
          title: 'Book details',
          onBack: () => Navigator.pop(context),
          child: BookInfoTabs(book: book),
        );
      },
    );
  }
}


class BookInfoTabs extends StatelessWidget {
  final Book book;

  const BookInfoTabs({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _BookHeader(book: book),
          const SizedBox(height: 40),
          const TabBar(
            indicatorColor: Color(0xFF112363),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.edit, size: 16), text: 'Detalles'),
              Tab(icon: Icon(Icons.lock, size: 16), text: 'Reseñas y valoraciones'),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: TabBarView(
              children: [
                _BookDetailsTab(book: book),
                const _BookReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _BookHeader extends StatelessWidget {
  final Book book;

  const _BookHeader({required this.book});

  @override
  Widget build(BuildContext context) {
    final List<String> formats = book.format.split(',').map((e) => e.trim()).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF112363)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              book.cover,
              height: 140,
              width: 90,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TapBubbleText(text: book.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),

                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: TapBubbleText(text: book.author, style: const TextStyle(color: Colors.grey),),),
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
                    if (formats.contains("Físico"))
                      const Row(
                        children: [
                          Icon(Icons.book, size: 18),
                          SizedBox(width: 4),
                          Text("Físico"),
                        ],
                      ),
                    if (formats.contains("Físico") && formats.contains("Digital"))
                      const SizedBox(width: 12),
                    if (formats.contains("Digital"))
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
                    if (book.state.toLowerCase() == "disponible")
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 4),
                          Text("Disponible"),
                        ],
                      ),
                    Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 18),
                        const SizedBox(width: 4),
                        const Text("Prestado", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        GestureDetector(
                          //onTap: () => _showLoanDetailsPopup(context, book),
                          child: const Text(
                            "Información del préstamo",
                            style: TextStyle(
                              color: Color(0xFF112363),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class _BookDetailsTab extends StatelessWidget {
  final Book book;

  const _BookDetailsTab({required this.book});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.blue),
              const SizedBox(width: 8),
              Text("${book.pagesNumber} páginas", style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.language, color: Colors.blue),
              const SizedBox(width: 8),
              Text(book.language, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2140AF), Color(0xFF6F8DEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Resumen",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  book.summary.isNotEmpty
                      ? book.summary
                      : "Este libro no tiene un resumen disponible.",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookReviewsTab extends StatelessWidget {
  const _BookReviewsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ReviewItem(name: "Angeles Marín Serrano", rating: 1, comment: ""),
        ReviewItem(name: "Manuel Crespo Mora", rating: 1, comment: ""),
      ],
    );
  }
}

class ReviewItem extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;

  const ReviewItem({
    super.key,
    required this.name,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
            ),
          ),
          if (comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(comment),
            ),
        ],
      ),
    );
  }
}
