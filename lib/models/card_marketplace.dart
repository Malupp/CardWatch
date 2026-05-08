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
  String get language =>
      propertiesHash['mtg_language']?.toString() ??
      propertiesHash['language']?.toString() ??
      'N/A';
  bool get isFoil =>
      propertiesHash['mtg_foil'] == true ||
      propertiesHash['mtg_foil'] == 'true' ||
      propertiesHash['foil'] == true ||
      propertiesHash['foil'] == 'true';
  bool get isSigned =>
      propertiesHash['signed'] == true || propertiesHash['signed'] == 'true';

  double? get priceThresholdEur {
    final value = propertiesHash['priceThresholdEur'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  CardMarketplace copyWith({
    CardUser? user,
    CardExpansion? expansion,
    CardPrice? price,
    Map<String, dynamic>? propertiesHash,
    int? quantity,
  }) {
    return CardMarketplace(
      user: user ?? this.user,
      expansion: expansion ?? this.expansion,
      price: price ?? this.price,
      propertiesHash: propertiesHash ?? this.propertiesHash,
      quantity: quantity ?? this.quantity,
    );
  }
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
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
    );
  }
}

class CardPrice {
  final String formatted;

  CardPrice({required this.formatted});

  factory CardPrice.fromJson(Map<String, dynamic> json) {
    final formatted = json['formatted'];
    if (formatted is String && formatted.isNotEmpty) {
      return CardPrice(formatted: formatted);
    }

    final cents = json['cents'];
    final currency = json['currency']?.toString() ?? '';
    if (cents is num) {
      return CardPrice(
        formatted: '${(cents / 100).toStringAsFixed(2)} $currency'.trim(),
      );
    }

    return CardPrice(formatted: '');
  }
}
