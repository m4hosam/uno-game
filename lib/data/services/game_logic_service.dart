import 'dart:math';
import '../../data/models/card_model.dart';
import '../../data/models/player_model.dart';

class GameLogicService {
  // 1. Deck Generation
  List<UnoCard> generateDeck() {
    List<UnoCard> deck = [];
    int idCounter = 0;

    // Helper to add card
    void addCard(CardColor color, CardType type, {int? value}) {
      deck.add(UnoCard(
        id: '${idCounter++}',
        color: color,
        type: type,
        value: value,
      ));
    }

    for (var color in CardColor.values) {
      if (color == CardColor.black) continue; // Skip wild color for now

      // Number 0 (one per color)
      addCard(color, CardType.number, value: 0);

      // Numbers 1-9 (two per color)
      for (int i = 1; i <= 9; i++) {
        addCard(color, CardType.number, value: i);
        addCard(color, CardType.number, value: i);
      }

      // Action cards (two per color)
      for (int i = 0; i < 2; i++) {
        addCard(color, CardType.skip);
        addCard(color, CardType.reverse);
        addCard(color, CardType.drawTwo);
      }
    }

    // Wild cards (4 each)
    for (int i = 0; i < 4; i++) {
      addCard(CardColor.black, CardType.wild);
      addCard(CardColor.black, CardType.wildDrawFour);
    }

    return deck;
  }

  // 2. Shuffling
  List<UnoCard> shuffleDeck(List<UnoCard> deck) {
    var newDeck = List<UnoCard>.from(deck);
    newDeck.shuffle(Random());
    return newDeck;
  }

  // 3. Card Validation
  bool canPlayCard(UnoCard card, UnoCard topCard, CardColor currentColor) {
    // Wild cards can always be played
    if (card.isWild) return true;

    // Match color
    if (card.color == currentColor) return true;

    // Match value (for number cards)
    if (card.type == CardType.number &&
        topCard.type == CardType.number &&
        card.value == topCard.value) {
      return true;
    }

    // Match symbol/type (for action cards)
    if (card.type != CardType.number && card.type == topCard.type) return true;

    return false;
  }

  // 4. Scoring
  int calculateScore(List<UnoCard> hand) {
    int score = 0;
    for (var card in hand) {
      if (card.type == CardType.number) {
        score += card.value ?? 0;
      } else if (card.isAction) {
        score += 20;
      } else if (card.isWild) {
        score += 50;
      }
    }
    return score;
  }

  // 5. Turn Management
  String getNextPlayerId(
      List<Player> players, String currentPlayerId, bool isClockwise) {
    int currentIndex = players.indexWhere((p) => p.id == currentPlayerId);
    if (currentIndex == -1) return players.first.id;

    int nextIndex;
    if (isClockwise) {
      nextIndex = (currentIndex + 1) % players.length;
    } else {
      nextIndex = (currentIndex - 1 + players.length) % players.length;
    }
    return players[nextIndex].id;
  }

  // 6. Special Card Effects helpers
  bool isSkip(UnoCard card) => card.type == CardType.skip;
  bool isReverse(UnoCard card) => card.type == CardType.reverse;
  bool isDrawTwo(UnoCard card) => card.type == CardType.drawTwo;
  bool isWildDrawFour(UnoCard card) => card.type == CardType.wildDrawFour;
}
