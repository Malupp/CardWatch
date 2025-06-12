class CardBlueprint {
  final int id;
  final String name;
  final String? imageUrl;
  
  CardBlueprint({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory CardBlueprint.fromJson(Map<String, dynamic> json) {
    return CardBlueprint(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}