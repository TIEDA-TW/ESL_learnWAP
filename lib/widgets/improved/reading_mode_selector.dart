import 'package:flutter/material.dart';
import '../../models/reading_mode.dart';

class ReadingModeSelector extends StatelessWidget {
  final ReadingMode currentMode;
  final Function(ReadingMode) onModeChanged;
  
  const ReadingModeSelector({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildModeButton(
            context,
            ReadingMode.reading,
            '點讀',
            Icons.volume_up,
            Colors.blue,
          ),
          _buildModeButton(
            context,
            ReadingMode.speaking,
            '跟讀',
            Icons.record_voice_over,
            Colors.orange,
          ),
          _buildModeButton(
            context,
            ReadingMode.translation,
            '翻譯',
            Icons.translate,
            Colors.green,
          ),
          _buildModeButton(
            context,
            ReadingMode.autoplay,
            '自動',
            Icons.play_circle_filled,
            Colors.purple,
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeButton(
    BuildContext context,
    ReadingMode mode,
    String label,
    IconData icon,
    Color color,
  ) {
    final bool isSelected = currentMode == mode;
    
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}