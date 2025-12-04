import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/card_model.dart';
import '../../data/models/player_model.dart';
import '../../data/models/game_room_model.dart';
import '../widgets/uno_card_widget.dart';
import '../providers/game_providers.dart';
import 'game_over_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final roomAsync = ref.watch(roomStreamProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(roomAsync.value?.id ?? 'Game'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: roomAsync.when(
        data: (room) {
          if (room == null || room.gameState == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = currentUserAsync.value;

          if (room.status == RoomStatus.finished) {
            final isWinner = room.gameState!.winnerId == currentUser?.id;
            int score = 0;
            if (isWinner) {
              final gameLogic = ref.read(gameLogicServiceProvider);
              for (var p in room.players) {
                if (p.id != currentUser?.id) {
                  score += gameLogic.calculateScore(p.hand ?? []);
                }
              }
            }
            return GameOverScreen(isWinner: isWinner, score: score);
          }

          final gameState = room.gameState!;

          // Identify my player object to get my cards
          final myPlayer = room.players.firstWhere(
            (p) => p.id == currentUser?.id,
            orElse: () => Player(id: 'unknown', name: 'Unknown'),
          );

          // Identify opponents
          final opponents =
              room.players.where((p) => p.id != currentUser?.id).toList();

          return SafeArea(
            child: Stack(
              children: [
                // Opponents Area
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: opponents
                        .map((player) => _buildOpponent(player))
                        .toList(),
                  ),
                ),

                // Center Area (Draw/Discard Piles)
                Positioned(
                  top: size.height * 0.3,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Draw Pile
                      GestureDetector(
                        onTap: () {
                          if (room.id.isNotEmpty && currentUser != null) {
                            ref
                                .read(gameRepositoryProvider)
                                .drawCard(room.id, currentUser.id);
                          }
                        },
                        child: const UnoCardWidget(
                            card: null, width: 80, height: 120),
                      ),
                      const SizedBox(width: 20),
                      // Discard Pile
                      if (gameState.topCard != null)
                        UnoCardWidget(
                            card: gameState.topCard, width: 80, height: 120),
                    ],
                  ),
                ),

                // Current Color Indicator
                Positioned(
                  top: size.height * 0.3 - 40,
                  right: 20,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _getCardColor(gameState.currentColor),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),

                // Turn Indicator
                if (gameState.currentPlayerId == currentUser?.id)
                  Positioned(
                    top: size.height * 0.2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Text(
                          "Your Turn!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Player Hand
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  height: 160,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (gameState.currentPlayerId == currentUser?.id &&
                          !(myPlayer.hand ?? []).any((c) =>
                              // Simple client-side check for prompt
                              c.isWild ||
                              c.color == gameState.currentColor ||
                              (c.type != CardType.number &&
                                  c.type == gameState.topCard?.type) ||
                              (c.type == CardType.number &&
                                  gameState.topCard?.type == CardType.number &&
                                  c.value == gameState.topCard?.value)))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "No playable cards! Tap the deck to draw.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: (myPlayer.hand ?? []).map((card) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: UnoCardWidget(
                                card: card,
                                width: 80,
                                height: 120,
                                onTap: () async {
                                  if (room.id.isNotEmpty &&
                                      currentUser != null) {
                                    if (card.isWild) {
                                      final chosenColor =
                                          await _showColorPickerDialog(context);
                                      if (chosenColor != null) {
                                        try {
                                          await ref
                                              .read(gameRepositoryProvider)
                                              .playCard(
                                                  room.id, currentUser.id, card,
                                                  chosenColor: chosenColor);
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text("Error: $e"),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    } else {
                                      try {
                                        await ref
                                            .read(gameRepositoryProvider)
                                            .playCard(
                                                room.id, currentUser.id, card);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Invalid move! Play a matching card."),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // UNO Button
                Positioned(
                  bottom: 180,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () async {
                      if (room.id.isNotEmpty && currentUser != null) {
                        await ref
                            .read(gameRepositoryProvider)
                            .callUno(room.id, currentUser.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("UNO Called!"),
                              backgroundColor: AppTheme.unoRed,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      }
                    },
                    backgroundColor: AppTheme.unoRed,
                    child: const Text('UNO',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildOpponent(Player player) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[800],
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          player.name,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.style, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                '${player.cardCount}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCardColor(CardColor? color) {
    switch (color) {
      case CardColor.red:
        return AppTheme.unoRed;
      case CardColor.blue:
        return AppTheme.unoBlue;
      case CardColor.green:
        return AppTheme.unoGreen;
      case CardColor.yellow:
        return AppTheme.unoYellow;
      default:
        return Colors.grey;
    }
  }

  Future<CardColor?> _showColorPickerDialog(BuildContext context) async {
    return showDialog<CardColor>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Choose Color',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorOption(context, CardColor.red, AppTheme.unoRed),
                _buildColorOption(context, CardColor.blue, AppTheme.unoBlue),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorOption(context, CardColor.green, AppTheme.unoGreen),
                _buildColorOption(
                    context, CardColor.yellow, AppTheme.unoYellow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(
      BuildContext context, CardColor color, Color uiColor) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(color),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: uiColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
