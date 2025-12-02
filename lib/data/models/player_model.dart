import 'package:equatable/equatable.dart';
import 'card_model.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final int cardCount; // For opponents view
  final bool isReady;
  final bool isHost;
  final bool hasCalledUno;
  final List<UnoCard>? hand;

  const Player({
    required this.id,
    required this.name,
    this.cardCount = 0,
    this.isReady = false,
    this.isHost = false,
    this.hasCalledUno = false,
    this.hand,
  });

  Player copyWith({
    String? id,
    String? name,
    int? cardCount,
    bool? isReady,
    bool? isHost,
    bool? hasCalledUno,
    List<UnoCard>? hand,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      cardCount: cardCount ?? this.cardCount,
      isReady: isReady ?? this.isReady,
      isHost: isHost ?? this.isHost,
      hasCalledUno: hasCalledUno ?? this.hasCalledUno,
      hand: hand ?? this.hand,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, cardCount, isReady, isHost, hasCalledUno, hand];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cardCount': cardCount,
      'isReady': isReady,
      'isHost': isHost,
      'hasCalledUno': hasCalledUno,
      'hand': hand?.map((x) => x.toMap()).toList(),
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      cardCount: map['cardCount'] ?? 0,
      isReady: map['isReady'] ?? false,
      isHost: map['isHost'] ?? false,
      hasCalledUno: map['hasCalledUno'] ?? false,
      hand: map['hand'] != null
          ? List<UnoCard>.from((map['hand'] as List)
              .map((x) => UnoCard.fromMap(Map<String, dynamic>.from(x as Map))))
          : null,
    );
  }
}
