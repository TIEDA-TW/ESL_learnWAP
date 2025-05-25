import 'package:flutter/material.dart';
import '../../models/game_data.dart';
import '../../widgets/game_timer.dart';
import '../../widgets/game_result.dart';

class PictureDiffScreen extends StatefulWidget {
  final PictureDiffData gameData;

  PictureDiffScreen({required this.gameData});

  @override
  _PictureDiffScreenState createState() => _PictureDiffScreenState();
}

class _PictureDiffScreenState extends State<PictureDiffScreen> {
  // Store found differences as Rects to easily check if a diff is already found
  Set<Rect> foundDiffAreas = {};
  bool isGameOver = false;
  double elapsedTime = 0;
  bool _showResult = false; // To control showing the GameResult widget

  // This will hold the GlobalKey for the modified image to get its size for correct coordinate scaling
  final GlobalKey _modifiedImageKey = GlobalKey();

  void onPictureTap(TapDownDetails details) {
    if (isGameOver || _showResult) return;

    final RenderBox? imageBox = _modifiedImageKey.currentContext?.findRenderObject() as RenderBox?;
    if (imageBox == null || !imageBox.hasSize) return;

    final tapPosition = details.localPosition;
    final imageSize = imageBox.size;

    // The diffAreas in PictureDiffData are assumed to be defined based on a specific
    // image dimension. If the displayed image is scaled, tap coordinates need to be
    // scaled or the Rects need to be scaled. For simplicity, we assume diffAreas
    // are defined for the original image size and the displayed image maintains that aspect ratio.
    // This example assumes widget.gameData.diffAreas are defined for the intrinsic size of the image.
    // If your images are displayed at a different size, you'll need to scale tapPosition accordingly.

    Rect? tappedArea;
    for (final area in widget.gameData.diffAreas) {
      // Create a slightly larger Rect for easier tapping, e.g., expand by 5 pixels
      final tappableArea = area.inflate(5.0);
      if (tappableArea.contains(tapPosition)) {
        tappedArea = area;
        break;
      }
    }

    if (tappedArea != null && !foundDiffAreas.contains(tappedArea)) {
      setState(() {
        foundDiffAreas.add(tappedArea!);
        if (foundDiffAreas.length == widget.gameData.diffCount) {
          isGameOver = true;
          _showResult = true; // Show result when game is over
        }
      });
    }
  }
  
  void _onTimerTick(double time) {
    if (!mounted || isGameOver) return;
    setState(() {
      elapsedTime = time;
    });
  }

  void _resetGame() {
    setState(() {
      foundDiffAreas.clear();
      isGameOver = false;
      _showResult = false;
      elapsedTime = 0;
      // Potentially, re-fetch game data or allow starting a new game.
      // For now, just resets the state of the current game.
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('圖片找茬 (${foundDiffAreas.length}/${widget.gameData.diffCount})'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: '重新開始',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GameTimer(
              onTick: _onTimerTick,
              isGameOver: isGameOver, // Pass game over state to timer
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      widget.gameData.originalImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(child: Text('圖片載入失敗')),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: GestureDetector(
                      onTapDown: onPictureTap,
                      child: Stack(
                        alignment: Alignment.topLeft, // Ensure Positioned works from top-left
                        children: [
                          Image.asset(
                            widget.gameData.modifiedImage,
                            key: _modifiedImageKey, // Assign key here
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Center(child: Text('圖片載入失敗')),
                          ),
                          // Display markers for found differences
                          ...foundDiffAreas.map((rect) {
                            // For simplicity, place a circle at the center of the Rect
                            // Adjust size and appearance as needed
                            return Positioned(
                              left: rect.left + rect.width / 2 - 15, // Center the icon (assuming icon size 30)
                              top: rect.top + rect.height / 2 - 15,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.red, width: 2),
                                ),
                                child: Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                              ),
                            );
                          }),
                          // Display markers for all differences if game is over (for review)
                          if (isGameOver && _showResult)
                            ...widget.gameData.diffAreas.where((area) => !foundDiffAreas.contains(area)).map((rect) {
                               return Positioned(
                                left: rect.left + rect.width / 2 - 15,
                                top: rect.top + rect.height / 2 - 15,
                                 child: Container(
                                   width: 30,
                                   height: 30,
                                   decoration: BoxDecoration(
                                     color: Colors.blue.withOpacity(0.3),
                                     shape: BoxShape.circle,
                                     border: Border.all(color: Colors.blue, width: 2),
                                   ),
                                   child: Icon(Icons.search, color: Colors.white, size: 20),
                                 ),
                               );
                             }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Game Result
          if (_showResult)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GameResult(
                correctCount: foundDiffAreas.length,
                totalCount: widget.gameData.diffCount,
                elapsedTime: elapsedTime,
                onPlayAgain: _resetGame,
                onReturnToMenu: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            )
          else if (isGameOver && !_showResult) // Handle case where game ends but result not shown yet
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: ElevatedButton(
                 child: Text("查看結果"),
                 onPressed: () => setState(() => _showResult = true),
               ),
             ),
        ],
      ),
    );
  }
}
