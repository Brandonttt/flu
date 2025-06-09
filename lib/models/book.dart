class Book {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  bool isFavorite;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    this.isFavorite = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['key'] ?? json['libroId'],
      title: json['title'] ?? json['titulo'],
      author: json['author_name']?.isNotEmpty == true 
          ? json['author_name'][0] 
          : json['autor'] ?? 'Autor desconocido',
      imageUrl: json['cover_i'] != null
          ? 'https://covers.openlibrary.org/b/id/${json['cover_i']}-M.jpg'
          : json['imagenUrl'] ?? 'https://via.placeholder.com/150',
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}