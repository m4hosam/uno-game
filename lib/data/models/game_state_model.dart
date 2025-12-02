import 'package:equatable/equatable.dart';
import 'card_model.dart';

class GameState extends Equatable {
  final String currentPlayerId;
  final bool isClockwise;
  final CardColor currentColor; // Important for Wild cards
  final UnoCard topCard;
  final int drawPileCount; // We don't sync the whole draw pile to everyone
  final String? winnerId;

  const GameState({
    required this.currentPlayerId,
    this.isClockwise = true,
    required this.currentColor,
    required this.topCard,
    required this.drawPileCount,
    this.winnerId,
  });

  @override
  List<Object?> get props => [
        currentPlayerId,
        isClockwise,
        currentColor,
        topCard,
        drawPileCount,
        winnerId
      ];

  Map<String, dynamic> toMap() {
    return {
      'currentPlayerId': currentPlayerId,
      'isClockwise': isClockwise,
      'currentColor': currentColor.index,
      'topCard': topCard.toMap(),
      'drawPileCount': drawPileCount,
      'winnerId': winnerId,
    };
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    return GameState(
      currentPlayerId: map['currentPlayerId'] ?? '',
      isClockwise: map['isClockwise'] ?? true,
      currentColor: CardColor.values[map['currentColor'] ?? 0],
      topCard:
          UnoCard.fromMap(Map<String, dynamic>.from(map['topCard'] as Map)),
      drawPileCount: map['drawPileCount'] ?? 0,
      winnerId: map['winnerId'],
    );
  }
}
