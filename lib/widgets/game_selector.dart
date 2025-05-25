import 'package:flutter/material.dart';

class Game {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final Color color;
  final Widget Function() builder;
  
  Game({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.color,
    required this.builder,
  });
}

class GameSelector extends StatelessWidget {
  final List<Game> games;
  final Function(Game) onGameSelected;
  
  const GameSelector({
    Key? key,
    required this.games,
    required this.onGameSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return GameCard(
          game: game,
          onTap: () => onGameSelected(game),
        );
      },
    );
  }
}

class GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  
  const GameCard({
    Key? key,
    required this.game,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: game.color,
                child: Center(
                  child: game.iconPath.endsWith('.svg')
                      ? SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.asset(
                            game.iconPath,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Icon(
                          Icons.games,
                          size: 80,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}