import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/book.dart';
import 'package:flutter_application_1/services/api_service.dart';

class BookProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Book> _searchResults = [];
  List<Book> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get searchResults => _searchResults;
  List<Book> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> searchBooks(String query) async {
    if (query.isEmpty) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _apiService.searchBooks(query);
      _searchResults = results
          .where((item) => 
              item['title'] != null && 
              (item['author_name']?.isNotEmpty ?? false))
          .map((item) => Book.fromJson(item))
          .toList();
      
      // Verificar estado de favoritos para cada libro
      for (var book in _searchResults) {
        try {
          book.isFavorite = await _apiService.isFavorite(book.id);
        } catch (_) {
          // Si falla, asumimos que no es favorito
          book.isFavorite = false;
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al buscar libros: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> fetchFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _apiService.getFavorites();
      _favorites = results.map((item) => Book.fromJson(item)).toList();
      _favorites.forEach((book) => book.isFavorite = true);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al obtener favoritos: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(Book book) async {
    try {
      if (book.isFavorite) {
        // Eliminar de favoritos
        await _apiService.removeFromFavorite(book.id);
        book.isFavorite = false;
        _favorites.removeWhere((item) => item.id == book.id);
      } else {
        // Agregar a favoritos
        await _apiService.addToFavorite(
          book.id, 
          book.title, 
          book.author, 
          book.imageUrl
        );
        book.isFavorite = true;
        _favorites.add(book);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al cambiar estado de favorito: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}