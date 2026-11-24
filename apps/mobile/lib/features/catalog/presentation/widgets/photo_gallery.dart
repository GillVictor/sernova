import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Swipeable photos with a "1 / 6" counter (shown when there are several).
class PhotoGallery extends StatefulWidget {
  const PhotoGallery({super.key, required this.urls});
  final List<String> urls;

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  int _index = 0;

  Widget get _placeholder => Container(
        color: AppColors.iconBubble,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, size: 56, color: AppColors.muted),
      );

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(fit: StackFit.expand, children: [
          if (urls.isEmpty)
            _placeholder
          else
            PageView.builder(
              itemCount: urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => Image.network(
                urls[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder,
              ),
            ),
          if (urls.length > 1)
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xCC1B1B1B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  Strings.t('detail.photoCounter',
                      params: {'current': _index + 1, 'total': urls.length}),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
