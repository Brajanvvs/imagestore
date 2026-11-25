import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

class AppImage extends StatelessWidget {
  const AppImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _ImageFallback();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const _ImageFallback(),
      errorWidget: (context, url, error) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE7E1D8),
      child: Center(
        child: Icon(Icons.image_outlined, color: AppColors.muted),
      ),
    );
  }
}
