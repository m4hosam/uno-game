import 'package:equatable/equatable.dart';
import 'card_model.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final int cardCount; // For opponents view
  final bool isReady;
  final bool isHost;
  final List<UnoCard>? hand;
  final bool saidUno;

  const Player({
    required this.id,
    required this.name,
    this.cardCount = 0,
    this.isReady = false,
    this.isHost = false,
    this.hand,
    this.saidUno = false,
  });

  Player copyWith({
    String? id,
    String? name,
    int? cardCount,
    bool? isReady,
    bool? isHost,
    List<UnoCard>? hand,
    bool? saidUno,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      cardCount: cardCount ?? this.cardCount,
      isReady: isReady ?? this.isReady,
      isHost: isHost ?? this.isHost,
      hand: hand ?? this.hand,
      saidUno: saidUno ?? this.saidUno,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, cardCount, isReady, isHost, hand, saidUno];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cardCount': cardCount,
      'isReady': isReady,
      'isHost': isHost,
      'hand': hand?.map((x) => x.toMap()).toList(),
      'saidUno': saidUno,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      cardCount: map['cardCount'] ?? 0,
      isReady: map['isReady'] ?? false,
      isHost: map['isHost'] ?? false,
      hand: map['hand'] != null
          ? List<UnoCard>.from((map['hand'] as List)
              .map((x) => UnoCard.fromMap(Map<String, dynamic>.from(x as Map))))
          : null,
      saidUno: map['saidUno'] ?? false,
    );
  }
}
