import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../state/auth_controller.dart';
import '../state/cart_controller.dart';
import '../widgets/app_image.dart';
import '../widgets/primary_button.dart';
import 'auth_required.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  Future<void> _add() async {
    final loggedIn = await requireAccount(
      context,
      message: 'Para agregar esta imagen al carrito inicia sesión o crea una cuenta.',
    );
    if (!loggedIn || !mounted) return;

    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();
    if (auth.user != null) {
      await cart.bindUser(auth.user!.id);
    }
    await cart.add(widget.product, _quantity);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.title} se agregó al carrito'),
        action: SnackBarAction(
          label: 'Ver carrito',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pop('cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 380,
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'product-${product.id}',
                          child: AppImage(url: product.imageUrl),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [Color(0x99000000), Color(0x00000000)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.copper,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.title,
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, height: 1.1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          money(product.price),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          product.description,
                          style: const TextStyle(fontSize: 16, height: 1.45, color: Color(0xFF3C3832)),
                        ),
                        if (product.attribution.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Fuente: ${product.attribution}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            elevation: 12,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          money(product.price * _quantity),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        const Text('Cantidad', style: TextStyle(color: AppColors.muted)),
                        const SizedBox(width: 8),
                        _QuantityBox(
                          quantity: _quantity,
                          onMinus: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          onPlus: _quantity < 20 ? () => setState(() => _quantity++) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(label: 'Agregar al carrito', onPressed: _add),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityBox extends StatelessWidget {
  const _QuantityBox({required this.quantity, required this.onMinus, required this.onPlus});

  final int quantity;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onMinus, icon: const Icon(Icons.remove), tooltip: 'Restar'),
          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add), tooltip: 'Sumar'),
        ],
      ),
    );
  }
}
