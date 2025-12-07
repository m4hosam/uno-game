import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final size = MediaQuery.of(context).size;
    final roomAsync = ref.watch(roomStreamProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1111), // Dark AppTheme background
      appBar: AppBar(
        title: Text(
          roomAsync.value?.name ?? 'The Fun Zone', // Fallback or room name
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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

          // Check for Game Over
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

          // Identify my player
          final myPlayer = room.players.firstWhere(
            (p) => p.id == currentUser?.id,
            orElse: () => Player(id: 'unknown', name: 'Unknown'),
          );

          // Identify opponents and order them relative to me
          final allPlayers = room.players;
          final myIndex = allPlayers.indexWhere((p) => p.id == currentUser?.id);
          final opponents = <Player>[];
          if (myIndex != -1) {
            for (int i = 1; i < allPlayers.length; i++) {
              opponents.add(allPlayers[(myIndex + i) % allPlayers.length]);
            }
          } else {
            opponents.addAll(allPlayers.where((p) => p.id != currentUser?.id));
          }

          return SafeArea(
            child: Stack(
              children: [
                // --- Opponents Layer ---
                if (opponents.isNotEmpty)
                  _buildOpponentPositioned(
                    context,
                    opponents: opponents,
                    index: opponents.length == 1 ? 0 : 1,
                    position: _calculateOpponentPosition(opponents.length, 1),
                    currentPlayerId: gameState.currentPlayerId,
                  ),

                if (opponents.length >= 2)
                  _buildOpponentPositioned(
                    context,
                    opponents: opponents,
                    index: 0,
                    position: _calculateOpponentPosition(opponents.length, 0),
                    currentPlayerId: gameState.currentPlayerId,
                  ),

                if (opponents.length >= 3)
                  _buildOpponentPositioned(
                    context,
                    opponents: opponents,
                    index: 2,
                    position: _calculateOpponentPosition(opponents.length, 2),
                    currentPlayerId: gameState.currentPlayerId,
                  ),

                // --- Center Area (Deck & Discard) ---
                Align(
                  alignment: const Alignment(0, -0.2),
                  child: SizedBox(
                    width: 280, // Enough space for deck + discard row
                    height: 180,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Draw Pile
                            GestureDetector(
                              onTap: () {
                                if (gameState.currentPlayerId ==
                                    currentUser?.id) {
                                  ref
                                      .read(gameRepositoryProvider)
                                      .drawCard(room.id, currentUser!.id);
                                }
                              },
                              child: Image.asset(
                                'docs/cards-assets/uno_deck.png',
                                width: 100, // Increased size
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(width: 30), // Increased spacing

                            // Discard Pile
                            if (gameState.topCard != null)
                              Transform.rotate(
                                angle: 0.1,
                                child: UnoCardWidget(
                                  card: gameState.topCard,
                                  width: 110, // Increased size
                                  height: 165,
                                ),
                              ),
                          ],
                        ),

                        // Color Indicator (Relative to Discard Pile)
                        if (gameState.topCard != null)
                          Positioned(
                            right: -30,
                            top: -40,
                            child: Column(
                              children: [
                                const Text("Color",
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 10)),
                                const SizedBox(height: 4),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _getCardColor(gameState.currentColor),
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                            color: _getCardColor(
                                                    gameState.currentColor)
                                                .withValues(alpha: 0.5),
                                            blurRadius: 8)
                                      ]),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // --- Current Turn Feedback (Center) ---
                if (gameState.currentPlayerId == currentUser?.id)
                  // Positioned(
                  //     top: size.height * 0.45,
                  //     left: 0,
                  //     right: 0,
                  //     child: Center(
                  //       child: IgnorePointer(
                  //         child: Container(
                  //           padding: const EdgeInsets.symmetric(
                  //               horizontal: 16, vertical: 6),
                  //           decoration: BoxDecoration(
                  //             color: Colors.black54,
                  //             borderRadius: BorderRadius.circular(20),
                  //             border: Border.all(color: Colors.green, width: 1),
                  //           ),
                  //           child: const Text("Your Turn",
                  //               style: TextStyle(
                  //                   color: Colors.green,
                  //                   fontWeight: FontWeight.bold)),
                  //         ),
                  //       ),
                  //     )),

                  // --- My Player Area (Bottom) ---
                  // Cards on TOP, Profile & Uno Button BELOW
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // My Hand
                        SizedBox(
                          height: 150,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: (myPlayer.hand ?? []).map((card) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: UnoCardWidget(
                                    card: card,
                                    width: 80,
                                    height: 120,
                                    onTap: () => _handleCardPlay(
                                        context, ref, room, currentUser!, card),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Profile & Controls Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Spacer to center Avatar if needed, or use MainAxisAlignment.center
                              // Using spaceBetween for distributed look as requested?
                              // Let's use Center with spacing
                              const Spacer(),

                              // My Avatar
                              _PlayerAvatar(
                                player: myPlayer,
                                isCurrentUser: true,
                                isActive:
                                    gameState.currentPlayerId == myPlayer.id,
                              ),

                              const SizedBox(width: 40),

                              // UNO Button
                              GestureDetector(
                                onTap: () => _handleCallUno(
                                    context, ref, room, currentUser!),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.unoRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                          offset: Offset(0, 2))
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text("UNO!",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ),
                              ),

                              const Spacer(),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildOpponentPositioned(BuildContext context,
      {required List<Player> opponents,
      required int index,
      required _OpponentPosition position,
      required String currentPlayerId}) {
    if (index >= opponents.length) return const SizedBox.shrink();
    final player = opponents[index];

    Alignment alignment;
    switch (position) {
      case _OpponentPosition.top:
        alignment = Alignment.topCenter;
        break;
      case _OpponentPosition.left:
        alignment = const Alignment(-0.9, -0.5);
        break;
      case _OpponentPosition.right:
        alignment = const Alignment(0.9, -0.5);
        break;
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _PlayerAvatar(
          player: player,
          isCurrentUser: false,
          isActive: currentPlayerId == player.id,
        ),
      ),
    );
  }

  _OpponentPosition _calculateOpponentPosition(int totalOpponents, int index) {
    if (totalOpponents == 1) return _OpponentPosition.top;
    if (totalOpponents == 2) {
      if (index == 0) return _OpponentPosition.right;
      return _OpponentPosition.top;
    }
    // 3 Opponents
    if (index == 0) return _OpponentPosition.right;
    if (index == 1) return _OpponentPosition.top;
    return _OpponentPosition.left;
  }

  Future<void> _handleCardPlay(BuildContext context, WidgetRef ref,
      GameRoom room, Player currentUser, UnoCard card) async {
    if (card.isWild) {
      final chosenColor = await _showColorPickerDialog(context);
      if (chosenColor != null) {
        await ref
            .read(gameRepositoryProvider)
            .playCard(room.id, currentUser.id, card, chosenColor: chosenColor);
      }
    } else {
      await ref
          .read(gameRepositoryProvider)
          .playCard(room.id, currentUser.id, card);
    }
  }

  Future<void> _handleCallUno(BuildContext context, WidgetRef ref,
      GameRoom room, Player currentUser) async {
    await ref.read(gameRepositoryProvider).callUno(room.id, currentUser.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("UNO Called!"),
          backgroundColor: AppTheme.unoRed,
          duration: Duration(seconds: 1)));
    }
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
        title:
            const Text('Choose Color', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildColorBtn(context, CardColor.red, AppTheme.unoRed),
              _buildColorBtn(context, CardColor.blue, AppTheme.unoBlue),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildColorBtn(context, CardColor.green, AppTheme.unoGreen),
              _buildColorBtn(context, CardColor.yellow, AppTheme.unoYellow),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildColorBtn(BuildContext context, CardColor c, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, c),
      child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2))),
    );
  }
}

enum _OpponentPosition { top, left, right }

class _PlayerAvatar extends StatelessWidget {
  final Player player;
  final bool isCurrentUser;
  final bool isActive;

  const _PlayerAvatar({
    required this.player,
    required this.isCurrentUser,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar Circle
            Container(
              padding: const EdgeInsets.all(3), // Border gap
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Colors.green : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isActive
                    ? [
                        const BoxShadow(
                            color: Colors.green,
                            blurRadius: 10,
                            spreadRadius: 1)
                      ]
                    : [],
              ),
              child: CircleAvatar(
                radius: isCurrentUser ? 30 : 25,
                backgroundColor: Colors.grey[800],
                // No background image, defaulting to icon
                child: const Icon(Icons.person, color: Colors.white70),
              ),
            ),

            // Card Count Badge (Top Right)
            if (!isCurrentUser)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${player.cardCount}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isCurrentUser ? 'You (${player.name})' : player.name,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        )
      ],
    );
  }
}
