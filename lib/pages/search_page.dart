import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/book.dart';
import 'package:flutter_application_1/providers/book_provider.dart';
import 'package:flutter_application_1/widgets/book_card.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    if (_formKey.currentState!.validate()) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.searchBooks(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar libros...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa un término de búsqueda';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: bookProvider.isLoading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: bookProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Buscar'),
                ),
              ],
            ),
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
          Expanded(
            child: bookProvider.searchResults.isEmpty && !bookProvider.isLoading
                ? const Center(
                    child: Text(
                      'No hay resultados para mostrar',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: bookProvider.searchResults.length,
                    itemBuilder: (context, index) {
                      final book = bookProvider.searchResults[index];
                      return BookCard(book: book);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}