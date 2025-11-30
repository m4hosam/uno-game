import 'package:flutter/material.dart';
import '../../data/models/card_model.dart';
import '../../core/theme/app_theme.dart';

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
          color: card != null ? _getCardColor(card!.color) : Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: card != null
            ? Center(child: _buildCardContent(card!))
            : _buildCardBack(),
      ),
    );
  }

  Color _getCardColor(CardColor color) {
    switch (color) {
      case CardColor.red:
        return AppTheme.unoRed;
      case CardColor.blue:
        return AppTheme.unoBlue;
      case CardColor.green:
        return AppTheme.unoGreen;
      case CardColor.yellow:
        return AppTheme.unoYellow;
      case CardColor.black:
        return Colors.black;
    }
  }

  Widget _buildCardContent(UnoCard card) {
    if (card.type == CardType.number) {
      return Text(
        card.value.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.6,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      );
    } else {
      IconData icon;
      switch (card.type) {
        case CardType.skip:
          icon = Icons.block;
          break;
        case CardType.reverse:
          icon = Icons.loop;
          break;
        case CardType.drawTwo:
          icon = Icons.filter_2;
          break;
        case CardType.wild:
          icon = Icons.colorize;
          break;
        case CardType.wildDrawFour:
          icon = Icons.filter_4;
          break;
        default:
          icon = Icons.error;
      }
      return Icon(
        icon,
        color: Colors.white,
        size: width * 0.6,
      );
    }
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF333333), Colors.black],
        ),
      ),
      child: Center(
        child: Container(
          width: width * 0.6,
          height: height * 0.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.unoRed, width: 2),
          ),
          child: const Center(
            child: Text(
              'UNO',
              style: TextStyle(
                color: AppTheme.unoYellow,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
