import 'package:flutter/material.dart';
import 'food_image.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> urls;
  final double aspectRatio;
  const ImageCarousel({super.key, required this.urls, this.aspectRatio = 16 / 7});
  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final _c = PageController();
  int _i = 0;

  void _go(int d, int n) => _c.animateToPage((_i + d).clamp(0, n - 1),
      duration: const Duration(milliseconds: 250), curve: Curves.easeOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls.isEmpty ? [''] : widget.urls;
    final n = urls.length;
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(children: [
        PageView.builder(
          controller: _c,
          itemCount: n,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, i) => SizedBox.expand(child: FoodImage(urls[i])),
        ),
        if (n > 1) ...[
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                  onPressed: _i == 0 ? null : () => _go(-1, n),
                  icon: const Icon(Icons.chevron_left)),
            ),
          ),
          Positioned(
            right: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                  onPressed: _i == n - 1 ? null : () => _go(1, n),
                  icon: const Icon(Icons.chevron_right)),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < n; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _i ? Colors.white : Colors.white54,
                  ),
                ),
            ]),
          ),
        ],
      ]),
    );
  }
}

void showGallery(BuildContext context, List<String> urls) => showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: ImageCarousel(urls: urls, aspectRatio: 1),
            ),
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ]),
        ),
      ),
    );