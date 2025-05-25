import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceAnimation extends StatelessWidget {
  final AnimationController pulseAnimation;
  final Color color;
  
  const VoiceAnimation({
    Key? key,
    required this.pulseAnimation,
    required this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: VoiceWavePainter(
            waveColor: color,
            animationValue: pulseAnimation.value,
          ),
        );
      },
    );
  }
}

class VoiceWavePainter extends CustomPainter {
  final Color waveColor;
  final double animationValue;
  
  VoiceWavePainter({
    required this.waveColor,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 繪製多個聲波圈
    for (int i = 0; i < 3; i++) {
      // 計算每個圈的偏移量，使它們交替出現
      final offset = (animationValue + (i / 3)) % 1.0;
      
      // 繪製聲波圈
      final radius = 10 + (offset * 20); // 半徑從10到30
      final opacity = (1 - offset) * 0.8; // 越大的圈透明度越低
      
      final paint = Paint()
        ..color = waveColor.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(center, radius, paint);
    }
    
    // 繪製麥克風圖標
    final iconPaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;
    
    // 簡單的麥克風形狀
    final iconPath = Path();
    
    // 麥克風頂部的圓形
    iconPath.addOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 2),
        width: 12,
        height: 12,
      ),
    );
    
    // 麥克風底部的矩形
    iconPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 5),
          width: 8,
          height: 10,
        ),
        const Radius.circular(4),
      ),
    );
    
    // 麥克風桿
    iconPath.moveTo(center.dx, center.dy + 10);
    iconPath.lineTo(center.dx, center.dy + 13);
    iconPath.lineTo(center.dx - 5, center.dy + 13);
    iconPath.lineTo(center.dx - 5, center.dy + 15);
    iconPath.lineTo(center.dx + 5, center.dy + 15);
    iconPath.lineTo(center.dx + 5, center.dy + 13);
    iconPath.lineTo(center.dx, center.dy + 13);
    iconPath.close();
    
    canvas.drawPath(iconPath, iconPaint);
  }
  
  @override
  bool shouldRepaint(covariant VoiceWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.waveColor != waveColor;
  }
}