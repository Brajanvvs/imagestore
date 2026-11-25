import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../state/catalog_controller.dart';
import '../widgets/app_image.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onMenu, required this.onOpenCart});

  final VoidCallback onMenu;
  final VoidCallback onOpenCart;

  Future<void> _openProduct(BuildContext context, Product product) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
    if (result == 'cart') onOpenCart();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final visible = catalog.visible;

    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: catalog.load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            leading: IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu),
              tooltip: 'Menú',
            ),
            title: const Text('IMAGO'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fotografías para llevar',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    catalog.meta.usesLiveApi
                        ? 'Catálogo conectado a Lorem Picsum (API gratuita).'
                        : 'Catálogo de muestra. Actualízalo con la API gratuita.',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  if (catalog.featured.isNotEmpty) ...[
                    _BannerCarousel(
                      products: catalog.featured,
                      onTap: (product) => _openProduct(context, product),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    onChanged: catalog.setQuery,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: catalog.categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final name = catalog.categories[index];
                        final selected = catalog.category == name;
                        return ChoiceChip(
                          label: Text(name),
                          selected: selected,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          selectedColor: AppColors.ink,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (_) => catalog.setCategory(name),
                        );
                      },
                    ),
                  ),
                  if (!catalog.meta.usesLiveApi) ...[
                    const SizedBox(height: 14),
                    _SyncBanner(catalog: catalog),
                  ],
                  if (catalog.error != null) ...[
                    const SizedBox(height: 14),
                    Text(catalog.error!, style: const TextStyle(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
          ),
          if (catalog.loading && catalog.products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: AppColors.ink)),
            )
          else if (visible.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay imágenes con ese nombre.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 16),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.66,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = visible[index];
                    return ProductCard(
                      product: product,
                      onTap: () => _openProduct(context, product),
                    );
                  },
                  childCount: visible.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.catalog});

  final CatalogController catalog;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0D2C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API de imágenes gratuita',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Usa Lorem Picsum: sin clave, sin tarjeta. Al sincronizar, estas fotos se reemplazan por resultados de la API.',
            style: TextStyle(color: AppColors.muted, height: 1.35),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: catalog.syncing
                  ? null
                  : () async {
                      final message = await catalog.syncCatalog();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    },
              child: Text(catalog.syncing ? 'Sincronizando…' : 'Cargar imágenes desde la API'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.products, required this.onTap});

  final List<Product> products;
  final ValueChanged<Product> onTap;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.products.isEmpty) return;
    if (_index >= widget.products.length) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.products.length < 2 || !_controller.hasClients) return;
      final next = (_index + 1) % widget.products.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.products.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final product = widget.products[index];
              return Padding(
                padding: const EdgeInsets.only(right: 0),
                child: GestureDetector(
                  onTap: () => widget.onTap(product),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppImage(url: product.cardImage),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0xCC1C1915)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'COLECCIÓN',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                money(product.price),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.products.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 7,
                width: i == _index ? 18 : 7,
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.ink : AppColors.line,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
