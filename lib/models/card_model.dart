class CardModel {
  final String name;
  final String imageUrl;
  final String expansion;
  final String price;
  final bool isFoil;
  final String condition;
  final String username;
  final int quantity;
  final bool graded;

  CardModel({
    required this.name,
    required this.imageUrl,
    required this.expansion,
    required this.price,
    required this.isFoil,
    required this.condition,
    required this.username,
    required this.quantity,
    required this.graded,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    final image = json['image_uris']?['art_crop'] ?? '';
    final price = json['prices']?['eur'] != null ? '${json['prices']['eur']} €' : 'N/A';

    return CardModel(
      name: json['name'] ?? '',
      imageUrl: image,
      expansion: json['set_name'] ?? '',
      price: price,
      isFoil: json['foil'] ?? false,
      condition: 'Near Mint', // fisso come da esempio Angular
      username: 'Scryfall', // fisso
      quantity: 1, // fisso
      graded: false, // fisso
    );
  }
}
