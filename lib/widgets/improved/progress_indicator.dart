import 'package:flutter/material.dart';

class CustomProgressIndicator extends StatelessWidget {
  final double value;
  final Color backgroundColor;
  final Color progressColor;
  final double height;
  final BorderRadius? borderRadius;
  
  const CustomProgressIndicator({
    Key? key,
    required this.value,
    required this.backgroundColor,
    required this.progressColor,
    this.height = 6.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final progressWidth = width * value.clamp(0.0, 1.0);
          
          return Row(
            children: [
              Container(
                width: progressWidth,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}