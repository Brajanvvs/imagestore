import 'product.dart';

class CartItem {
  const CartItem({
    required this.productId,
    required this.title,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.quantity,
  });

  final int productId;
  final String title;
  final String category;
  final double price;
  final String imageUrl;
  final int quantity;

  double get lineTotal => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      title: title,
      category: category,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItem.fromProduct(Product product, int quantity) {
    return CartItem(
      productId: product.id,
      title: product.title,
      category: product.category,
      price: product.price,
      imageUrl: product.cardImage,
      quantity: quantity,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'] as int,
      title: '${json['title'] ?? ''}',
      category: '${json['category'] ?? ''}',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: '${json['image_url'] ?? ''}',
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'title': title,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'quantity': quantity,
    };
  }
}
