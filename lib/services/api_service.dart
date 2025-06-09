import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

class ApiService {
  // URLs para diferentes entornos
  static const List<String> possibleBaseUrls = [
    'http://10.0.2.2:8085/api',  // Para emulador Android
    'http://localhost:8085/api',  // Para iOS simulator
  ];
  
  String baseUrl = possibleBaseUrls.first;
  bool _initialized = false;
  
  // Para las cabeceras de autenticación si implementas tokens
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer $token', // Si implementas JWT
  };

  // Método para verificar conexión al iniciar la app
  Future<bool> initializeConnection() async {
    if (_initialized) return true;
    
    final workingUrl = await findWorkingBaseUrl();
    if (workingUrl != null) {
      baseUrl = workingUrl;
      _initialized = true;
      debugPrint('Conexión establecida con: $baseUrl');
      return true;
    }
    
    debugPrint('No se pudo establecer conexión con el servidor');
    return false;
  }

  // Método para probar la conexión con diferentes URLs
  Future<String?> findWorkingBaseUrl() async {
    for (String url in possibleBaseUrls) {
      try {
        debugPrint('Intentando conectar a: $url/auth/ping');
        final response = await http.get(
          Uri.parse('$url/auth/ping'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          debugPrint('Conexión exitosa a: $url');
          return url;
        }
      } catch (e) {
        debugPrint('Error con URL $url: $e');
      }
    }
    return null;
  }

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Verificar conexión
      if (!_initialized) {
        await initializeConnection();
      }
      
      debugPrint('Enviando solicitud de login a: $baseUrl/auth/login');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      debugPrint('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = response.body.isNotEmpty 
            ? jsonDecode(response.body)['error'] ?? 'Error de autenticación'
            : 'Error de autenticación';
        throw Exception(error);
      }
    } on SocketException {
      throw Exception('No se pudo conectar al servidor. Verifica tu conexión a internet y que el servidor esté en funcionamiento.');
    } on TimeoutException {
      throw Exception('La conexión al servidor ha expirado. Intente nuevamente.');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Registro
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      // Verificar conexión
      if (!_initialized) {
        await initializeConnection();
      }
      
      debugPrint('Enviando solicitud de registro a: $baseUrl/auth/register');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username, 
          'email': email, 
          'password': password
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = response.body.isNotEmpty 
            ? jsonDecode(response.body)['error'] ?? 'Error en el registro'
            : 'Error en el registro';
        throw Exception(error);
      }
    } on SocketException {
      throw Exception('No se pudo conectar al servidor. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('La conexión al servidor ha expirado. Intente nuevamente.');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Buscar libros
  Future<List<dynamic>> searchBooks(String query) async {
    try {
      debugPrint('Buscando libros: $query');
      final response = await http.get(
        Uri.parse('https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Libros encontrados: ${data['docs'].length}');
        return data['docs'];
      } else {
        throw Exception('Error en la búsqueda de libros: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en búsqueda de libros: $e');
      throw Exception('Error en la búsqueda de libros: $e');
    }
  }

  // Obtener favoritos
  Future<List<dynamic>> getFavorites() async {
    try {
      // Verificar conexión
      if (!_initialized) {
        await initializeConnection();
      }
      
      debugPrint('Obteniendo favoritos de: $baseUrl/libros/favoritos');
      final response = await http.get(
        Uri.parse('$baseUrl/libros/favoritos'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Favoritos obtenidos: ${data.length}');
        return data;
      } else {
        final error = response.body.isNotEmpty 
            ? jsonDecode(response.body)['error'] ?? 'Error al obtener favoritos'
            : 'Error al obtener favoritos';
        throw Exception(error);
      }
    } on SocketException {
      throw Exception('No se pudo conectar al servidor. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('La conexión al servidor ha expirado. Intente nuevamente.');
    } catch (e) {
      throw Exception('Error al obtener favoritos: $e');
    }
  }

  // Agregar a favoritos
  Future<Map<String, dynamic>> addToFavorite(String bookId, String title, String author, String imageUrl) async {
    try {
      // Verificar conexión
      if (!_initialized) {
        await initializeConnection();
      }
      
      debugPrint('Agregando a favoritos: $title');
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/libros/favoritos/agregar'),
      );

      request.fields.addAll({
        'libroId': bookId,
        'titulo': title,
        'autor': author,
        'imagenUrl': imageUrl,
      });

      var streamedResponse = await request.send().timeout(const Duration(seconds: 10));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = response.body.isNotEmpty 
            ? jsonDecode(response.body)['error'] ?? 'Error al agregar favorito'
            : 'Error al agregar favorito';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Error al agregar favorito: $e');
    }
  }

  // Eliminar de favoritos
  Future<Map<String, dynamic>> removeFromFavorite(String bookId) async {
    try {
      // Verificar conexión
      if (!_initialized) {
        await initializeConnection();
      }
      
      debugPrint('Eliminando de favoritos: $bookId');
      final response = await http.delete(
        Uri.parse('$baseUrl/libros/favoritos/eliminar/$bookId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = response.body.isNotEmpty 
            ? jsonDecode(response.body)['error'] ?? 'Error al eliminar favorito'
            : 'Error al eliminar favorito';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Error al eliminar favorito: $e');
    }
  }

  // Verificar si un libro es favorito
  Future<bool> isFavorite(String bookId) async {
    try {
      // Verificar conexión
      if (!_initialized) {
        await initializeConnection();
      }
      
      debugPrint('Verificando si es favorito: $bookId');
      final response = await http.get(
        Uri.parse('$baseUrl/libros/favoritos/estado/$bookId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['esFavorito'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error al verificar favorito: $e');
      return false;
    }
  }
  
  // Método genérico para verificar servidor
  Future<bool> checkServer() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/auth/ping')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}