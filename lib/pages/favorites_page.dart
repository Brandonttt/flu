import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/book_provider.dart';
import 'package:flutter_application_1/widgets/book_card.dart';
import 'package:provider/provider.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).fetchFavorites();
    });
  }

  Future<void> _refreshFavorites() async {
    await Provider.of<BookProvider>(context, listen: false).fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshFavorites,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Mis Libros Favoritos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (bookProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    bookProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (bookProvider.isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (bookProvider.favorites.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No tienes libros favoritos',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: bookProvider.favorites.length,
                    itemBuilder: (context, index) {
                      final book = bookProvider.favorites[index];
                      return BookCard(book: book);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}