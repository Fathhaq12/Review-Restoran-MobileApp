class Review {
  final int id;
  final int rating;
  final String comment;
  final int userId;
  final int restaurantId;
  final int? menuId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? username; // From User relation

  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userId,
    required this.restaurantId,
    this.menuId,
    required this.createdAt,
    required this.updatedAt,
    this.username,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'],
      comment: json['comment'],
      userId: json['userId'],
      restaurantId: json['restaurantId'],
      menuId: json['menuId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      username: json['User']?['username'] ?? json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'comment': comment,
      'userId': userId,
      'restaurantId': restaurantId,
      'menuId': menuId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'username': username,
    };
  }

  // Helper getters for compatibility
  int get reviewId => id;
}
