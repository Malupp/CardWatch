import 'package:uuid/uuid.dart';

class CardGroup {
  final String id;
  final String title;
  final List<String> cardKeys;

  CardGroup({
    String? id,
    required this.title,
    required this.cardKeys,
  }) : id = id ?? const Uuid().v4();

  factory CardGroup.fromJson(Map<String, dynamic> json) => CardGroup(
    id: json['id'] as String,
    title: json['title'] as String,
    cardKeys: List<String>.from(json['cardKeys'] as List<dynamic> ?? []),
  );

  Map<String, dynamic> toJson() => ({
    'id': id,
    'title': title,
    'cardKeys': cardKeys,
  });

  CardGroup copyWith({
    String? id,
    String? title,
    List<String>? cardKeys,
  }) {
    return CardGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      cardKeys: cardKeys ?? this.cardKeys,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
