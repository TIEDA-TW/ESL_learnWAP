import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ImageUtils {
  static double calculateImageScale(Size containerSize) {
    final widthScale = containerSize.width / AppConfig.defaultImageWidth;
    final heightScale = containerSize.height / AppConfig.defaultImageHeight;
    return widthScale < heightScale ? widthScale : heightScale;
  }

  static Rect calculateScaledRect(Map<String, double> coordinates, double scale, double topOffset) {
    return Rect.fromLTWH(
      coordinates['x1']! * scale,
      coordinates['y1']! * scale + topOffset,
      (coordinates['x2']! - coordinates['x1']!) * scale,
      (coordinates['y2']! - coordinates['y1']!) * scale,
    );
  }
}