class CardModel {
  final String name;
  final String imageUrl;
  final String expansion;
  final String price;
  final bool isFoil;
  final String condition;
  final String username;
  final int? quantity;
  final bool graded;
  final String artist;

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
    required this.artist,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    final image = json['image_uris']?['art_crop'] ?? '';
    final price = json['prices']?['eur'] != null ? '${json['prices']['eur']} €' : 'N/A';
    final priceFoil = json['prices']?['eur_foil'] != null ? '${json['prices']['eur_foil']} €' : 'N/A';

    return CardModel(
      name: json['name'] ?? '',
      imageUrl: image,
      expansion: json['set_name'] ?? '',
      price: price + (json['foil'] == true ? ' (Foil: $priceFoil)' : ''),
      isFoil: json['foil'] ?? false,
      condition: 'Near Mint', // fisso come da esempio Angular
      username: 'Scryfall', // fisso
      quantity: json['quantity'],
      graded: false, // fisso
      artist: json['artist'] ?? '',
    );
  }
}
