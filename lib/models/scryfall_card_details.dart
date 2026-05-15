class ScryfallCardDetails {
  final String name;
  final String imageUrl;
  final String oracleText;
  final String rarity;
  final double? manaValue;
  final List<String> colors;
  final String setName;
  final String setCode;
  final String typeLine;
  final Map<String, String> legalities;
  final Map<String, String> prices;

  ScryfallCardDetails({
    required this.name,
    required this.imageUrl,
    required this.oracleText,
    required this.rarity,
    required this.manaValue,
    required this.colors,
    required this.setName,
    required this.setCode,
    required this.typeLine,
    required this.legalities,
    required this.prices,
  });

  factory ScryfallCardDetails.fromJson(Map<String, dynamic> json) {
    final imageUris =
        json['image_uris'] ?? json['card_faces']?[0]?['image_uris'];
    final faces = json['card_faces'];

    String oracleText = json['oracle_text']?.toString() ?? '';
    if (oracleText.isEmpty && faces is List) {
      oracleText = faces
          .map((face) => face['oracle_text']?.toString() ?? '')
          .where((text) => text.isNotEmpty)
          .join('\n\n');
    }

    final legalitiesJson = json['legalities'];
    final legalities = <String, String>{};
    if (legalitiesJson is Map) {
      legalitiesJson.forEach((key, value) {
        legalities[key.toString()] = value.toString();
      });
    }

    final pricesJson = json['prices'];
    final prices = <String, String>{};
    if (pricesJson is Map) {
      const labels = {
        'usd': 'USD',
        'usd_foil': 'USD Foil',
        'eur': 'EUR',
        'eur_foil': 'EUR Foil',
        'tix': 'MTGO',
      };

      for (final entry in labels.entries) {
        final value = pricesJson[entry.key]?.toString();
        if (value != null && value.isNotEmpty && value != 'null') {
          prices[entry.value] = value;
        }
      }
    }

    final colorsJson = json['colors'] ?? json['color_identity'];
    final colors = colorsJson is List
        ? colorsJson.map((color) => color.toString()).toList()
        : <String>[];
    final cmc = json['cmc'];

    return ScryfallCardDetails(
      name: json['name']?.toString() ?? '',
      imageUrl:
          imageUris?['large']?.toString() ??
          imageUris?['normal']?.toString() ??
          imageUris?['art_crop']?.toString() ??
          '',
      oracleText: oracleText,
      rarity: json['rarity']?.toString() ?? '',
      manaValue: cmc is num ? cmc.toDouble() : double.tryParse('$cmc'),
      colors: colors,
      setName: json['set_name']?.toString() ?? '',
      setCode: json['set']?.toString() ?? '',
      typeLine: json['type_line']?.toString() ?? '',
      legalities: legalities,
      prices: prices,
    );
  }

  String get displayRarity {
    if (rarity.isEmpty) return 'N/A';
    return rarity[0].toUpperCase() + rarity.substring(1);
  }
}
