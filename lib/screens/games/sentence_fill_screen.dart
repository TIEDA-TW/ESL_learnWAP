  
import 'package:flutter/material.dart';
import '../../models/game_data.dart';
import '../../widgets/game_timer.dart';
import '../../widgets/game_result.dart';

class SentenceFillScreen extends StatefulWidget {
  final SentenceFillData gameData;

  SentenceFillScreen({required this.gameData});

  @override
  _SentenceFillScreenState createState() => _SentenceFillScreenState();
}

class _SentenceFillScreenState extends State<SentenceFillScreen> {
  late List<String> displayWords; // Words displayed on screen, including blanks
  late List<String> originalWords; // The original correct sentence words
  late List<String> currentOptions;
  
  Map<int, String?> filledBlanks = {}; // Tracks what's filled in each blank index
  List<int> blankIndices = []; // Stores original indices of blanks

  bool isGameOver = false;
  int score = 0; // Number of correctly filled blanks
  double elapsedTime = 0;
  
  String? feedbackMessage; // For "Correct!" or "Try again!"
  String? selectedOption; // To highlight the selected option

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    originalWords = widget.gameData.sentence.split(' ');
    displayWords = List.from(originalWords);
    currentOptions = List.from(widget.gameData.options)..shuffle();
    
    blankIndices.clear();
    filledBlanks.clear();

    // Identify blank positions
    for (int i = 0; i < originalWords.length; i++) {
      if (originalWords[i] == '___' || originalWords[i].contains('___')) { // Assuming '___' marks a blank
        blankIndices.add(i);
        displayWords[i] = '___'; // Ensure it's represented as a blank
      }
    }
    
    isGameOver = false;
    score = 0;
    elapsedTime = 0;
    feedbackMessage = null;
    selectedOption = null;
  }

  void _onTimerTick(double time) {
    if (!mounted || isGameOver) return;
    setState(() {
      elapsedTime = time;
    });
  }

  void onOptionTap(String option) {
    if (isGameOver) return;

    setState(() {
      selectedOption = option;
      feedbackMessage = null; // Clear previous feedback
    });

    int currentBlankIndex = -1;
    // Find the first *actual* blank index that hasn't been correctly filled
    for (int bIndex in blankIndices) {
      if (filledBlanks[bIndex] == null) { // If this blank is not yet (correctly) filled
        currentBlankIndex = bIndex;
        break;
      }
    }

    if (currentBlankIndex != -1) {
      // Check if the tapped option is the correct word for this blank
      if (originalWords[currentBlankIndex] == option) {
        setState(() {
          displayWords[currentBlankIndex] = option;
          filledBlanks[currentBlankIndex] = option; // Mark as correctly filled
          score++;
          feedbackMessage = 'Correct!';
          // Remove option from list to prevent re-use if desired, or just disable it
          // For simplicity, we'll just give feedback. Re-enabling for mistakes could be a feature.
        });
      } else {
        setState(() {
          feedbackMessage = 'Try again!';
        });
      }

      // Check for game over
      if (filledBlanks.length == blankIndices.length) {
         bool allCorrect = true;
         for(int bIndex in blankIndices){
             if(filledBlanks[bIndex] != originalWords[bIndex]){
                 allCorrect = false;
                 break;
             }
         }
         if(allCorrect){
            setState(() {
              isGameOver = true;
            });
         }
      }
    }
    
    // Clear selection and feedback after a short delay
    Future.delayed(Duration(milliseconds: 800), () {
      if(mounted){
        setState(() {
          selectedOption = null;
          if (feedbackMessage == 'Correct!') feedbackMessage = null; // Only clear correct feedback quickly
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Calculate the number of original blanks
    final totalBlanks = blankIndices.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('句子填空 ($score/$totalBlanks)'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() => _initializeGame()),
            tooltip: '重新開始',
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GameTimer(
              onTick: _onTimerTick,
              isGameOver: isGameOver,
            ),
          ),
          Expanded(
            flex: 2, // Give more space to the sentence
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  children: displayWords.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String word = entry.value;
                    bool isBlank = blankIndices.contains(idx) && filledBlanks[idx] == null;
                    bool isCorrectlyFilled = blankIndices.contains(idx) && filledBlanks[idx] != null;
                    
                    return TextSpan(
                      text: word == "___" ? " ____ " : " $word ",
                      style: TextStyle(
                        fontWeight: isBlank || isCorrectlyFilled ? FontWeight.bold : FontWeight.normal,
                        color: isCorrectlyFilled ? theme.colorScheme.primary : 
                               isBlank ? theme.colorScheme.secondary : 
                               theme.colorScheme.onSurfaceVariant,
                        decoration: isBlank ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: theme.colorScheme.secondary,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          if (feedbackMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                feedbackMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: feedbackMessage == 'Correct!' ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            flex: 3, // Give more space to options
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3, // Responsive columns
                childAspectRatio: 2.5, // Adjust for button like appearance
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: currentOptions.length,
              itemBuilder: (context, index) {
                final option = currentOptions[index];
                bool isSelected = selectedOption == option;
                // Example: You could add logic to disable options if they've been correctly used
                // and you don't want them to be selectable again for other blanks.
                // bool isDisabled = filledBlanks.containsValue(option) && !blankIndices.any((bi) => originalWords[bi] == option && filledBlanks[bi] == null);

                return GestureDetector(
                  onTap: () => onOptionTap(option),
                  child: Card(
                    elevation: isSelected ? 6 : 2,
                    color: isSelected 
                        ? (feedbackMessage == 'Correct!' ? Colors.green[100] : (feedbackMessage == 'Try again!' ? Colors.red[100] : theme.colorScheme.primaryContainer))
                        : theme.colorScheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          option,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isGameOver)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GameResult(
                correctCount: score,
                totalCount: totalBlanks, // Use total number of original blanks
                elapsedTime: elapsedTime,
                onPlayAgain: () => setState(() => _initializeGame()),
                onReturnToMenu: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
