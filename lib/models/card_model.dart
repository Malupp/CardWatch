class CardModel {
  final String name;
  final String imageUrl; // art_crop
  final String? imageNormalUrl; // normal
  final String expansion;
  final String price;
  final bool isFoil;
  final String condition;
  final String username;
  final int? quantity;
  final bool graded;
  final String artist;
  final String? manaCost;
  final String? typeLine;
  final String? oracleText;
  final String? power;
  final String? toughness;

  CardModel({
    required this.name,
    required this.imageUrl,
    this.imageNormalUrl,
    required this.expansion,
    required this.price,
    required this.isFoil,
    required this.condition,
    required this.username,
    required this.quantity,
    required this.graded,
    required this.artist,
    this.manaCost,
    this.typeLine,
    this.oracleText,
    this.power,
    this.toughness,
  });

  // Factory per dati da Scryfall API
  factory CardModel.fromScryfallJson(Map<String, dynamic> json) {
    final artCrop = json['image_uris']?['art_crop'] ?? '';
    final normal = json['image_uris']?['normal'] ?? '';
    final price = json['prices']?['eur'] != null ? '${json['prices']['eur']} €' : 'N/A';
    final priceFoil = json['prices']?['eur_foil'] != null ? '${json['prices']['eur_foil']} €' : 'N/A';

    return CardModel(
      name: json['name'] ?? '',
      imageUrl: artCrop,
      imageNormalUrl: normal,
      expansion: json['set_name'] ?? '',
      price: price + (json['foil'] == true ? ' (Foil: $priceFoil)' : ''),
      isFoil: json['foil'] ?? false,
      condition: 'N/A', // Verrà aggiornato se disponibile dal marketplace
      username: 'N/A', // Verrà aggiornato se disponibile dal marketplace
      quantity: json['quantity'],
      graded: false, // Verrà aggiornato se disponibile dal marketplace
      artist: json['artist'] ?? '',
      manaCost: json['mana_cost'],
      typeLine: json['type_line'],
      oracleText: json['oracle_text'],
      power: json['power'],
      toughness: json['toughness'],
    );
  }

  // Factory per dati da Marketplace API
  factory CardModel.fromMarketplaceJson(Map<String, dynamic> json) {
    return CardModel(
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      expansion: json['set_name'] ?? '',
      price: json['price'] != null ? '${json['price']} €' : 'N/A',
      isFoil: json['is_foil'] ?? false,
      condition: json['condition'] ?? 'N/A',
      username: json['seller_name'] ?? 'N/A',
      quantity: json['quantity'],
      graded: json['is_graded'] ?? false,
      artist: json['artist'] ?? '',
      manaCost: json['mana_cost'],
      typeLine: json['type_line'],
      oracleText: json['oracle_text'],
      power: json['power'],
      toughness: json['toughness'],
    );
  }

  // Metodo per aggiornare i dati con informazioni dal marketplace
  CardModel mergeWithMarketplaceData(Map<String, dynamic> marketplaceData) {
    // Gestione intelligente dei prezzi
    String finalPrice = price;
    
    // Se abbiamo prezzi da Scryfall (normale + foil), li manteniamo
    if (price.contains('(Foil:') && price != 'N/A') {
      // Mantieni i prezzi di Scryfall se disponibili
      finalPrice = price;
    } else if (marketplaceData['price'] != null && marketplaceData['price'] != 'N/A') {
      // Se non abbiamo prezzi di Scryfall, usa quelli del marketplace
      finalPrice = '${marketplaceData['price']} €';
      
      // Se la carta è foil nel marketplace, aggiungi indicazione
      if (marketplaceData['is_foil'] == true) {
        finalPrice += ' (Foil)';
      }
    }
    
    return CardModel(
      name: name,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : (marketplaceData['image_url'] ?? ''),
      imageNormalUrl: imageNormalUrl,
      expansion: expansion.isNotEmpty ? expansion : (marketplaceData['set_name'] ?? ''),
      price: finalPrice,
      isFoil: isFoil || (marketplaceData['is_foil'] ?? false),
      condition: condition != 'N/A' ? condition : (marketplaceData['condition'] ?? 'N/A'),
      username: username != 'N/A' ? username : (marketplaceData['seller_name'] ?? 'N/A'),
      quantity: quantity ?? marketplaceData['quantity'],
      graded: graded || (marketplaceData['is_graded'] ?? false),
      artist: artist.isNotEmpty ? artist : (marketplaceData['artist'] ?? ''),
      manaCost: manaCost,
      typeLine: typeLine,
      oracleText: oracleText,
      power: power,
      toughness: toughness,
    );
  }

  // Factory legacy per compatibilità
  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel.fromScryfallJson(json);
  }
}
