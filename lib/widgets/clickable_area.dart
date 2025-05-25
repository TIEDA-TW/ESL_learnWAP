import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ClickableArea extends StatelessWidget {
  final VoidCallback onTap;
  final double width;
  final double height;

  const ClickableArea({
    Key? key,
    required this.onTap,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue,
            width: AppConfig.clickableAreaBorderWidth,
          ),
          color: Colors.blue.withOpacity(AppConfig.clickableAreaOpacity),
        ),
      ),
    );
  }
}