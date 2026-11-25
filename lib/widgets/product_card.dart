import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/product.dart';
import 'app_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'product-${product.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AppImage(url: product.cardImage),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.category.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              money(product.price),
              style: const TextStyle(
                color: AppColors.copper,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
