import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';

class GameOverScreen extends StatelessWidget {
  final bool isWinner;
  final int score;

  const GameOverScreen({
    super.key,
    required this.isWinner,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isWinner ? AppTheme.unoGreen : AppTheme.unoRed,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isWinner
                    ? Icons.emoji_events
                    : Icons.sentiment_very_dissatisfied,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                isWinner
                    ? l10n.winner
                    : 'Game Over', // TODO: Localize 'Game Over'
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Score: $score',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor:
                      isWinner ? AppTheme.unoGreen : AppTheme.unoRed,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  l10n.playAgain,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
