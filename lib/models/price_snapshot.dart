class PriceSnapshot {
  final DateTime date;
  final double priceEur;

  const PriceSnapshot({required this.date, required this.priceEur});

  factory PriceSnapshot.fromJson(Map<String, dynamic> json) {
    final price = json['price'];
    return PriceSnapshot(
      date: DateTime.parse(json['date']?.toString() ?? ''),
      priceEur: price is num ? price.toDouble() : double.parse('$price'),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'price': priceEur,
  };
}
