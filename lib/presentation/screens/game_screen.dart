import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
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

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  AppLocalizations? _l10n;
  late AnimationController _pulseController;
  late AnimationController _cardFanController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _cardFanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cardFanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final roomAsync = ref.watch(roomStreamProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1111),
      appBar: AppBar(
        title: Text(
          roomAsync.value?.name ?? _l10n?.roomDefaultName ?? 'The Fun Zone',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black26,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
            orElse: () =>
                Player(id: 'unknown', name: _l10n?.unknownPlayer ?? 'Unknown'),
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

          final isMyTurn = gameState.currentPlayerId == currentUser?.id;

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
                  alignment: const Alignment(0, -0.35),
                  child:
                      _buildCenterPile(gameState, room, currentUser, isMyTurn),
                ),

                // --- My Player Area (Bottom) ---
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildMyPlayerArea(
                    context,
                    myPlayer,
                    room,
                    currentUser,
                    gameState,
                    isMyTurn,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text('${_l10n?.errorPrefix ?? 'Error: '}$err',
                style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildCenterPile(
      dynamic gameState, GameRoom room, dynamic currentUser, bool isMyTurn) {
    return Container(
      width: 300,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Draw Pile with pulse animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale =
                      isMyTurn ? 1.0 + (_pulseController.value * 0.05) : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: GestureDetector(
                      onTap: () {
                        if (isMyTurn) {
                          ref
                              .read(gameRepositoryProvider)
                              .drawCard(room.id, currentUser!.id);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isMyTurn
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'docs/cards-assets/uno_deck.png',
                            width: 100,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 40),

              // Discard Pile with rotation animation
              if (gameState.topCard != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 0.1),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, angle, child) {
                    return Transform.rotate(
                      angle: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _getCardColor(gameState.currentColor)
                                  .withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: UnoCardWidget(
                          card: gameState.topCard,
                          width: 110,
                          height: 165,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),

          // Enhanced Color Indicator
          if (gameState.topCard != null)
            Positioned(
              right: -20,
              top: -60,
              child: Column(
                children: [
                  Text(
                    _l10n?.colorLabel ?? "COLOR",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getCardColor(gameState.currentColor),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _getCardColor(gameState.currentColor)
                              .withValues(alpha: 0.6),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyPlayerArea(
    BuildContext context,
    Player myPlayer,
    GameRoom room,
    dynamic currentUser,
    dynamic gameState,
    bool isMyTurn,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // My Hand with enhanced animations
          SizedBox(
            height: 160,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: (myPlayer.hand ?? []).map((card) {
                  // Removed delay for instant feedback

                  return TweenAnimationBuilder<double>(
                    key: ValueKey(card.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _AnimatedCard(
                              card: card,
                              onTap: isMyTurn
                                  ? () => _handleCardPlay(
                                      context, ref, room, currentUser!, card)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bottom Section: Profile Center, UNO Button Right
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Profile Avatar (Center)
                  _PlayerAvatar(
                    player: myPlayer,
                    isCurrentUser: true,
                    isActive: isMyTurn,
                  ),

                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _UnoButton(
                      onTap: () =>
                          _handleCallUno(context, ref, room, currentUser!),
                      label: _l10n?.uno ?? "UNO!",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        alignment = const Alignment(-0.9, -0.4);
        break;
      case _OpponentPosition.right:
        alignment = const Alignment(0.9, -0.4);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text(_l10n?.unoCalled ?? "UNO Called!",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppTheme.unoRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _l10n?.chooseColor ?? 'Choose Color',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorBtn(context, CardColor.red, AppTheme.unoRed),
                  _buildColorBtn(context, CardColor.blue, AppTheme.unoBlue),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorBtn(context, CardColor.green, AppTheme.unoGreen),
                  _buildColorBtn(context, CardColor.yellow, AppTheme.unoYellow),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorBtn(BuildContext context, CardColor c, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, c),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

enum _OpponentPosition { top, left, right }

// Enhanced Animated Card Widget
class _AnimatedCard extends StatefulWidget {
  final UnoCard card;
  final VoidCallback? onTap;

  const _AnimatedCard({
    required this.card,
    this.onTap,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..translate(0.0, _isPressed ? 10.0 : 0.0)
          ..scale(_isPressed ? 0.95 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: UnoCardWidget(
            card: widget.card,
            width: 80,
            height: 120,
          ),
        ),
      ),
    );
  }
}

// Enhanced UNO Button
class _UnoButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const _UnoButton({required this.onTap, required this.label});

  @override
  State<_UnoButton> createState() => _UnoButtonState();
}

class _UnoButtonState extends State<_UnoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.unoRed,
                    Color(0xFFB71C1C),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.unoRed.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  const BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Enhanced Player Avatar
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
            // Avatar Circle with enhanced styling
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Colors.green, Colors.lightGreenAccent],
                      )
                    : null,
                border: Border.all(
                  color: isActive ? Colors.transparent : Colors.white24,
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 3,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[800]!,
                      Colors.grey[900]!,
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: isCurrentUser ? 24 : 28,
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    Icons.person,
                    color: Colors.white70,
                    size: isCurrentUser ? 24 : 28,
                  ),
                ),
              ),
            ),

            // Card Count Badge (Top Right)
            if (!isCurrentUser)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Colors.grey],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '${player.cardCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.green : Colors.white12,
              width: 1,
            ),
          ),
          child: Text(
            isCurrentUser ? 'You (${player.name})' : player.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isCurrentUser ? 14 : 12,
            ),
          ),
        ),
      ],
    );
  }
}
