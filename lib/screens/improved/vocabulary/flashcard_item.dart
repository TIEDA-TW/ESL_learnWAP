import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/book_model.dart';
import '../../../services/improved/tts_service.dart';

class FlashcardItem extends StatefulWidget {
  final TextRegion textRegion;
  final bool showTranslationFirst; // New property

  const FlashcardItem({
    Key? key,
    required this.textRegion,
    this.showTranslationFirst = false, // Default to showing word first
  }) : super(key: key);

  @override
  _FlashcardItemState createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<FlashcardItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _showFront = !widget.showTranslationFirst; // Set initial side

    // Listen for animation completion to update the text visibility
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFront = !_showFront;
        });
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (!_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardContentStyle = theme.textTheme.headlineMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );

    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                height: 200, // Fixed height for the card
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                alignment: Alignment.center,
                // Determine which side to show based on animation progress
                child: _animation.value < 0.5
                    ? (_showFront
                        ? Text(widget.textRegion.text, style: cardContentStyle, textAlign: TextAlign.center)
                        : Text(widget.textRegion.translation ?? 'No translation', style: cardContentStyle, textAlign: TextAlign.center))
                    : Transform( // Content for the "back" of the card (mid-flip)
                        transform: Matrix4.identity()..rotateY(math.pi), // Rotate content to face correctly
                        alignment: Alignment.center,
                        child: (_showFront
                            ? Text(widget.textRegion.translation ?? 'No translation', style: cardContentStyle, textAlign: TextAlign.center)
                            : Text(widget.textRegion.text, style: cardContentStyle, textAlign: TextAlign.center)),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Simple IconButton for TTS, can be placed outside the card if needed
class SpeakButton extends StatelessWidget {
  final String text;
  final double speechRate;
  
  const SpeakButton({
    Key? key, 
    required this.text,
    this.speechRate = 0.7, // 預設語速
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.volume_up, color: Theme.of(context).colorScheme.primary),
      iconSize: 30,
      onPressed: () {
        TtsService().speak(text, rate: speechRate);
      },
      tooltip: 'Play sound',
    );
  }
}
