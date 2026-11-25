class StoreMeta {
  const StoreMeta({
    required this.source,
    required this.providerReady,
    required this.taxRate,
    required this.shippingFlat,
    required this.freeShippingFrom,
    required this.categories,
  });

  final String source;
  final bool providerReady;
  final double taxRate;
  final double shippingFlat;
  final double freeShippingFrom;
  final List<String> categories;

  bool get usesLiveApi => source == 'picsum' || source == 'pexels';

  static const fallback = StoreMeta(
    source: 'sample',
    providerReady: true,
    taxRate: 0.19,
    shippingFlat: 3.5,
    freeShippingFrom: 60,
    categories: [],
  );

  factory StoreMeta.fromJson(Map<String, dynamic> json) {
    final raw = json['categories'];
    return StoreMeta(
      source: '${json['source'] ?? 'sample'}',
      providerReady: json['provider_ready'] != false,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.19,
      shippingFlat: (json['shipping_flat'] as num?)?.toDouble() ?? 3.5,
      freeShippingFrom: (json['free_shipping_from'] as num?)?.toDouble() ?? 60,
      categories: raw is List ? raw.map((item) => '$item').toList() : const [],
    );
  }
}
