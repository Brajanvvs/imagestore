class OrderLine {
  const OrderLine({
    required this.productId,
    required this.title,
    required this.unitPrice,
    required this.quantity,
    required this.imageUrl,
    required this.lineTotal,
  });

  final int productId;
  final String title;
  final double unitPrice;
  final int quantity;
  final String imageUrl;
  final double lineTotal;

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      productId: json['product_id'] as int? ?? 0,
      title: '${json['title'] ?? ''}',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: '${json['image_url'] ?? ''}',
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final String status;
  final DateTime createdAt;
  final List<OrderLine> items;

  String get statusLabel {
    if (status == 'paid') return 'Pagado (simulado)';
    return status;
  }

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return StoreOrder(
      id: json['id'] as int,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: '${json['status'] ?? ''}',
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      items: rawItems is List
          ? rawItems
              .map((item) => OrderLine.fromJson(item as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}
