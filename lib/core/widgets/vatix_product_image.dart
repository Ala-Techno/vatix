import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vatix/core/theme/app_colors.dart';

/// [VatixProductImage] — Unified product image display widget
/// Completely zero-flicker with in-memory cache for fast Base64 decoding.
class VatixProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final bool isAvailable;

  // In-memory cache for decoded bytes to prevent re-decoding on every rebuild
  static final Map<String, Uint8List> _memoryBytesCache = {};

  const VatixProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildFallback();
    }

    final raw = imageUrl!.trim();

    // 1. If image is stored as Data URI or Base64
    if (raw.startsWith('data:image') || _isLikelyBase64(raw)) {
      try {
        // Fetch bytes from cache if available to prevent flickering
        Uint8List? bytes = _memoryBytesCache[raw];
        if (bytes == null) {
          final base64Data = raw.contains(',') ? raw.split(',').last : raw;
          bytes = base64Decode(base64Data);
          // Keep in cache
          _memoryBytesCache[raw] = bytes;
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            gaplessPlayback: true, // Prevents flicker during widget rebuilds
            errorBuilder: (_, __, ___) => _buildFallback(),
          ),
        );
      } catch (_) {
        return _buildFallback();
      }
    }

    // 2. If image is a network URL (HTTP / HTTPS / CDN)
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: raw,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryLight.withValues(alpha: 0.5),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildFallback(),
      ),
    );
  }

  bool _isLikelyBase64(String str) {
    return str.length > 100 && !str.startsWith('http');
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.primaryLight.withValues(alpha: 0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_rounded,
          size: (width != null && width! < 60) ? 24 : 32,
          color: isAvailable ? AppColors.primaryLight : AppColors.textHint,
        ),
      ),
    );
  }
}
