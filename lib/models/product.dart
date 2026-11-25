class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.source,
    required this.sourcePage,
    required this.attribution,
    required this.featured,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final String imageUrl;
  final String thumbnailUrl;
  final String source;
  final String sourcePage;
  final String attribution;
  final bool featured;

  String get cardImage => thumbnailUrl.isNotEmpty ? thumbnailUrl : imageUrl;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      category: '${json['category'] ?? ''}',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: '${json['image_url'] ?? ''}',
      thumbnailUrl: '${json['thumbnail_url'] ?? ''}',
      source: '${json['source'] ?? ''}',
      sourcePage: '${json['source_page'] ?? ''}',
      attribution: '${json['attribution'] ?? ''}',
      featured: json['featured'] == true,
    );
  }
}
