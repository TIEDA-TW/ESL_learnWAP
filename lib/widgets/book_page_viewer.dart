import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/book_models_fixed.dart';
import '../config/app_config.dart';
import '../utils/image_utils.dart';
import 'clickable_area.dart';

class BookPageViewer extends StatelessWidget {
  final BookPage page;
  final String currentCategory;
  final double imageScale;
  final Function(String) onElementTap;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  final GlobalKey imageKey;
  final Function(Size)? onImageLoad;

  const BookPageViewer({
    Key? key,
    required this.page,
    required this.currentCategory,
    required this.imageScale,
    required this.onElementTap,
    required this.imageKey,
    this.onNextPage,
    this.onPreviousPage,
    this.onImageLoad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Image.asset(
            '${AppConfig.booksPath}/${page.image}',
            key: imageKey,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              log('Error loading image: $error\n$stackTrace');
              return Text('圖片載入錯誤: $error');
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null && onImageLoad != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (imageKey.currentContext != null) {
                    final RenderBox renderBox = 
                        imageKey.currentContext!.findRenderObject() as RenderBox;
                    onImageLoad!(renderBox.size);
                  }
                });
              }
              if (frame == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return child;
            },
          ),
        ),
        ...page.elements
            .where((element) => element.category == currentCategory)
            .map((element) {
              final rect = ImageUtils.calculateScaledRect(
                element.coordinates,
                imageScale,
                kToolbarHeight,
              );
              
              return Positioned(
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: ClickableArea(
                  onTap: () => onElementTap(element.audioFile),
                  width: rect.width,
                  height: rect.height,
                ),
              );
            }).toList(),
        if (onPreviousPage != null)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: onPreviousPage,
                ),
              ),
            ),
          ),
        if (onNextPage != null)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: onNextPage,
                ),
              ),
            ),
          ),
      ],
    );
  }
}