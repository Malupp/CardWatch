class ScryfallSet {
  final String code;
  final String name;

  ScryfallSet({required this.code, required this.name});

  factory ScryfallSet.fromJson(Map<String, dynamic> json) {
    return ScryfallSet(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

