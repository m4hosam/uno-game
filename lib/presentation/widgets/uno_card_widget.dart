import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../data/models/card_model.dart';

class UnoCardWidget extends StatelessWidget {
  final UnoCard? card; // Null means face down (back of card)
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool isSelected;

  const UnoCardWidget({
    super.key,
    this.card,
    this.width = 60,
    this.height = 90,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        margin: EdgeInsets.only(bottom: isSelected ? 20 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: card != null
            ? ZoomIn(
                child: Image.asset(_getAssetPath(card!), fit: BoxFit.contain))
            : Image.asset('docs/cards-assets/uno_deck.png',
                fit: BoxFit.contain),
      ),
    );
  }

  String _getAssetPath(UnoCard card) {
    const basePath = 'docs/cards-assets';

    if (card.type == CardType.wild) {
      return '$basePath/change_colour_red.png'; // Default wild image, maybe dynamic based on state?
      // Note: Ideally we show the chosen color if it's already played, but the asset is generic "change_colour".
      // For a card in hand, it's just "change_colour".
    }
    if (card.type == CardType.wildDrawFour) {
      return '$basePath/draw_four_128.png';
    }

    String colorPrefix = '';
    switch (card.color) {
      case CardColor.red:
        colorPrefix = 'red';
        break;
      case CardColor.blue:
        colorPrefix = 'blue';
        break;
      case CardColor.green:
        colorPrefix = 'green';
        break;
      case CardColor.yellow:
        colorPrefix = 'yellow';
        break;
      default:
        colorPrefix = 'red'; // Fallback
    }

    if (card.type == CardType.number) {
      return '$basePath/${colorPrefix}_${card.value}.png';
    } else if (card.type == CardType.skip) {
      return '$basePath/${colorPrefix}_skip.png';
    } else if (card.type == CardType.reverse) {
      return '$basePath/${colorPrefix}_reverse.png';
    } else if (card.type == CardType.drawTwo) {
      return '$basePath/${colorPrefix}_draw2.png';
    }

    return '$basePath/uno_deck.png'; // Fallback
  }
}
