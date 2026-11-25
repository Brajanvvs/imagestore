import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/product.dart';
import '../models/store_meta.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this._api);

  final ApiClient _api;

  List<Product> products = [];
  StoreMeta meta = StoreMeta.fallback;
  bool loading = false;
  bool syncing = false;
  String? error;
  String query = '';
  String category = 'Todos';

  List<String> get categories {
    if (meta.categories.isNotEmpty) return ['Todos', ...meta.categories];
    final names = products.map((product) => product.category).toSet().toList()..sort();
    return ['Todos', ...names];
  }

  List<Product> get featured {
    final flagged = products.where((product) => product.featured).toList();
    if (flagged.isNotEmpty) return flagged.take(6).toList();
    return products.take(4).toList();
  }

  List<Product> get visible {
    final text = query.trim().toLowerCase();
    return products.where((product) {
      final categoryOk = category == 'Todos' || product.category == category;
      final textOk = text.isEmpty || product.title.toLowerCase().contains(text);
      return categoryOk && textOk;
    }).toList();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  Future<void> load() async {
    final showSpinner = products.isEmpty;
    if (showSpinner) {
      loading = true;
      notifyListeners();
    }
    error = null;
    try {
      final data = await _api.products();
      meta = StoreMeta.fromJson(data['meta'] as Map<String, dynamic>);
      final list = data['products'] as List<dynamic>? ?? [];
      products = list
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
      if (!categories.contains(category)) category = 'Todos';
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudieron cargar las imágenes';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String> syncCatalog() async {
    syncing = true;
    notifyListeners();
    try {
      final result = await _api.syncProducts();
      await load();
      return '${result['message'] ?? 'Catálogo actualizado'}';
    } on ApiException catch (exception) {
      return exception.message;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }
}
