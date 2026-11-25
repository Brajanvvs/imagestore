import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/store_meta.dart';
import '../state/cart_controller.dart';
import '../state/catalog_controller.dart';
import '../widgets/app_image.dart';
import '../widgets/primary_button.dart';
import 'orders_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.onMenu, required this.onGoHome});

  final VoidCallback onMenu;
  final VoidCallback onGoHome;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  var _busy = false;

  Future<void> _checkout() async {
    final cart = context.read<CartController>();
    final api = context.read<ApiClient>();
    setState(() => _busy = true);
    try {
      final order = await cart.checkout(api);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Compra simulada'),
          content: Text(
            'Pedido #${order.id}\n'
            'Total ${money(order.total)}\n\n'
            'No se hizo un cobro real. El pedido quedó guardado en Mis pedidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Seguir viendo'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
                );
              },
              child: const Text('Ver pedidos'),
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final meta = context.watch<CatalogController>().meta;
    final taxPercent = (meta.taxRate * 100).round();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onMenu,
          icon: const Icon(Icons.menu),
          tooltip: 'Menú',
        ),
        title: const Text('CARRITO'),
      ),
      body: cart.items.isEmpty
          ? _EmptyCart(onGoHome: widget.onGoHome)
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: AppImage(url: item.imageUrl),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${money(item.price)} c/u',
                                      style: const TextStyle(color: AppColors.muted),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _MiniQty(
                                          quantity: item.quantity,
                                          onMinus: () => cart.setQuantity(item.productId, item.quantity - 1),
                                          onPlus: () => cart.setQuantity(item.productId, item.quantity + 1),
                                        ),
                                        const Spacer(),
                                        Text(
                                          money(item.lineTotal),
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => cart.remove(item.productId),
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _Summary(
                  meta: meta,
                  subtotal: cart.subtotal,
                  tax: cart.taxOf(meta),
                  shipping: cart.shippingOf(meta),
                  total: cart.totalOf(meta),
                  taxPercent: taxPercent,
                  busy: _busy,
                  onCheckout: _checkout,
                ),
              ],
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, size: 64, color: AppColors.muted),
            const SizedBox(height: 16),
            const Text(
              'Tu carrito está vacío',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando agregues una imagen, vas a verla aquí con su precio y la cantidad.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onGoHome, child: const Text('Ver imágenes')),
          ],
        ),
      ),
    );
  }
}

class _MiniQty extends StatelessWidget {
  const _MiniQty({required this.quantity, required this.onMinus, required this.onPlus});

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onMinus,
            child: const SizedBox(width: 32, height: 32, child: Icon(Icons.remove, size: 18)),
          ),
          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
          InkWell(
            onTap: quantity >= 20 ? null : onPlus,
            child: const SizedBox(width: 32, height: 32, child: Icon(Icons.add, size: 18)),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.meta,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.taxPercent,
    required this.busy,
    required this.onCheckout,
  });

  final StoreMeta meta;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final int taxPercent;
  final bool busy;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final shippingLabel = shipping == 0 ? 'Gratis' : money(shipping);
    return Material(
      color: Colors.white,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            children: [
              _line('Subtotal', money(subtotal)),
              _line('IVA ($taxPercent%)', money(tax)),
              _line('Envío', shippingLabel),
              const Divider(height: 18),
              _line('Total', money(total), emphasize: true),
              const SizedBox(height: 4),
              Text(
                'Envío ${money(meta.shippingFlat)} · gratis desde ${money(meta.freeShippingFrom)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Proceder al pago', busy: busy, onPressed: onCheckout),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value, {bool emphasize = false}) {
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
      fontSize: emphasize ? 18 : 15,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style.copyWith(color: emphasize ? AppColors.copper : AppColors.ink)),
        ],
      ),
    );
  }
}
