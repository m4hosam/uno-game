import 'package:equatable/equatable.dart';

enum CardColor { red, blue, green, yellow, black }

enum CardType { number, skip, reverse, drawTwo, wild, wildDrawFour }

class UnoCard extends Equatable {
  final String id;
  final CardColor color;
  final CardType type;
  final int? value; // 0-9 for number cards

  const UnoCard({
    required this.id,
    required this.color,
    required this.type,
    this.value,
  });

  bool get isWild => type == CardType.wild || type == CardType.wildDrawFour;
  bool get isAction =>
      type == CardType.skip ||
      type == CardType.reverse ||
      type == CardType.drawTwo;

  @override
  List<Object?> get props => [id, color, type, value];

  // To/From Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color.index,
      'type': type.index,
      'value': value,
    };
  }

  factory UnoCard.fromMap(Map<String, dynamic> map) {
    return UnoCard(
      id: map['id'] ?? '',
      color: CardColor.values[map['color'] ?? 0],
      type: CardType.values[map['type'] ?? 0],
      value: map['value'],
    );
  }
}
