import 'package:flutter/material.dart';
import '../../models/reading_mode.dart';

class ReadingControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final double currentScale;
  final bool isAutoPlaying;
  final ReadingMode readingMode;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onResetZoom;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onStartAutoplay;
  final VoidCallback? onStopAutoplay;

  const ReadingControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.currentScale,
    required this.isAutoPlaying,
    required this.readingMode,
    this.onZoomIn,
    this.onZoomOut,
    this.onResetZoom,
    this.onPreviousPage,
    this.onNextPage,
    this.onStartAutoplay,
    this.onStopAutoplay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 頁數顯示
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '第 ${currentPage + 1} 頁 / 共 $totalPages 頁',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // 縮放控制
          Row(
            children: [
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildControlButton(
                    icon: Icons.zoom_out,
                    onPressed: onZoomOut,
                    tooltip: '縮小',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${(currentScale * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildControlButton(
                    icon: Icons.zoom_in,
                    onPressed: onZoomIn,
                    tooltip: '放大',
                  ),
                  const SizedBox(width: 16),
                  _buildControlButton(
                    icon: Icons.refresh,
                    onPressed: onResetZoom,
                    tooltip: '重置縮放',
                  ),
                ],
              ),
              const Spacer(),
              if (readingMode == ReadingMode.autoplay)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: isAutoPlaying
                      ? ElevatedButton.icon(
                          onPressed: onStopAutoplay,
                          icon: const Icon(Icons.stop),
                          label: const Text('結束'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: onStartAutoplay,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('開始'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // 縮放控制區域結束
          // 移除了頁面導航區域，因為上方AppBar已有頁數指引，且上一頁/下一頁按鈕將移至圖片顯示區左右兩側

                    // 自動播放控制已整合至縮放按鈕同一行靠右
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Colors.blue,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: onPressed != null ? Colors.blue : Colors.grey,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: onPressed != null ? Colors.blue : Colors.grey,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
