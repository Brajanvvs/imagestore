import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/store_meta.dart';
import '../models/store_order.dart';

class CartController extends ChangeNotifier {
  CartController(this._prefs);

  final SharedPreferences _prefs;
  int? _userId;
  List<CartItem> items = [];

  int get count => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => roundMoney(items.fold<double>(0, (sum, item) => sum + item.lineTotal));

  double taxOf(StoreMeta meta) => roundMoney(subtotal * meta.taxRate);

  double shippingOf(StoreMeta meta) {
    if (subtotal <= 0 || subtotal >= meta.freeShippingFrom) return 0;
    return meta.shippingFlat;
  }

  double totalOf(StoreMeta meta) => roundMoney(subtotal + taxOf(meta) + shippingOf(meta));

  Future<void> bindUser(int? userId) async {
    _userId = userId;
    if (userId == null) {
      items = [];
      notifyListeners();
      return;
    }
    final raw = _prefs.getString('cart_$userId');
    if (raw == null || raw.isEmpty) {
      items = [];
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      items = decoded
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> add(Product product, int quantity) async {
    final index = items.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      final next = items[index].quantity + quantity;
      items[index] = items[index].copyWith(quantity: next > 20 ? 20 : next);
    } else {
      items.add(CartItem.fromProduct(product, quantity));
    }
    notifyListeners();
    await _persist();
  }

  Future<void> setQuantity(int productId, int quantity) async {
    if (quantity < 1) {
      await remove(productId);
      return;
    }
    final index = items.indexWhere((item) => item.productId == productId);
    if (index < 0) return;
    items[index] = items[index].copyWith(quantity: quantity > 20 ? 20 : quantity);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(int productId) async {
    items.removeWhere((item) => item.productId == productId);
    notifyListeners();
    await _persist();
  }

  Future<StoreOrder> checkout(ApiClient api) async {
    final order = StoreOrder.fromJson(
      await api.checkout([
        for (final item in items) {'product_id': item.productId, 'quantity': item.quantity},
      ]),
    );
    items = [];
    notifyListeners();
    await _persist();
    return order;
  }

  Future<void> _persist() async {
    final userId = _userId;
    if (userId == null) return;
    await _prefs.setString(
      'cart_$userId',
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
