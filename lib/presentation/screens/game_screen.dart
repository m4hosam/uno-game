import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/card_model.dart';
import '../../data/models/player_model.dart';
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

          final gameState = room.gameState!;
          final currentUser = currentUserAsync.value;

          // Identify my player object to get my cards
          final myPlayer = room.players.firstWhere(
            (p) => p.id == currentUser?.id,
            orElse: () => Player(id: 'unknown', name: 'Unknown'),
          );

          // Identify opponents
          final opponents =
              room.players.where((p) => p.id != currentUser?.id).toList();

          return Stack(
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
                        if (room.id.isNotEmpty) {
                          ref.read(gameRepositoryProvider).drawCard(room.id);
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

              // Player Hand
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                height: 160,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: (myPlayer.hand ?? []).map((card) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: UnoCardWidget(
                          card: card,
                          width: 80,
                          height: 120,
                          onTap: () {
                            if (room.id.isNotEmpty) {
                              ref
                                  .read(gameRepositoryProvider)
                                  .playCard(room.id, card);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // UNO Button
              Positioned(
                bottom: 180,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    if (room.id.isNotEmpty) {
                      ref.read(gameRepositoryProvider).callUno(room.id);
                    }
                  },
                  backgroundColor: AppTheme.unoRed,
                  child: const Text('UNO',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
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
}
