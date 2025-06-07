class Menu {
  final int id;
  final String name;
  final String description;
  final double price;
  final int restaurantId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Menu({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.restaurantId,
    this.createdAt,
    this.updatedAt,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price:
          (json['price'] is String)
              ? double.parse(json['price'])
              : json['price']?.toDouble() ?? 0.0,
      restaurantId: json['restaurantId'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'restaurantId': restaurantId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Currency formatting helper
  String formatPrice({String currency = 'IDR'}) {
    switch (currency) {
      case 'USD':
        return '\$${(price / 15500).toStringAsFixed(2)}';
      case 'EUR':
        return '€${(price / 17000).toStringAsFixed(2)}';
      case 'JPY':
        return '¥${(price / 150).toStringAsFixed(0)}';
      default:
        final String priceStr = price.toInt().toString();
        String result = '';
        int counter = 0;
        for (int i = priceStr.length - 1; i >= 0; i--) {
          if (counter > 0 && counter % 3 == 0) {
            result = '.$result';
          }
          result = priceStr[i] + result;
          counter++;
        }
        return 'Rp $result';
    }
  }
}
