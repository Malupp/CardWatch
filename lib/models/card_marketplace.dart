class CardMarketplace {
  final CardUser user;
  final CardExpansion expansion;
  final CardPrice price;
  final Map<String, dynamic> propertiesHash;
  final int quantity;

  CardMarketplace({
    required this.user,
    required this.expansion,
    required this.price,
    required this.propertiesHash,
    required this.quantity,
  });

  factory CardMarketplace.fromJson(Map<String, dynamic> json) {
    return CardMarketplace(
      user: CardUser.fromJson(json['user'] ?? {}),
      expansion: CardExpansion.fromJson(json['expansion'] ?? {}),
      price: CardPrice.fromJson(json['price'] ?? {}),
      propertiesHash: Map<String, dynamic>.from(json['properties_hash'] ?? {}),
      quantity: json['quantity'] ?? 0,
    );
  }

  // Getter per ottenere la condizione dalla properties_hash
  String get condition => propertiesHash['condition']?.toString() ?? 'N/A';
  
  // Altri getter utili che potresti aver bisogno
  String get language => propertiesHash['language']?.toString() ?? 'N/A';
  bool get isFoil => propertiesHash['foil'] == true || propertiesHash['foil'] == 'true';
  bool get isSigned => propertiesHash['signed'] == true || propertiesHash['signed'] == 'true';
}

class CardUser {
  final String username;

  CardUser({required this.username});

  factory CardUser.fromJson(Map<String, dynamic> json) {
    return CardUser(username: json['username'] ?? '');
  }
}

class CardExpansion {
  final String nameEn;
  final String code;
  final int id;

  CardExpansion({required this.nameEn, required this.code, required this.id});

  factory CardExpansion.fromJson(Map<String, dynamic> json) {
    return CardExpansion(
      nameEn: json['name_en'] ?? '',
      code: json['code'] ?? '',
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
    );
  }
}

class CardPrice {
  final String formatted;

  CardPrice({required this.formatted});

  factory CardPrice.fromJson(Map<String, dynamic> json) {
    return CardPrice(formatted: json['formatted'] ?? '');
  }
}