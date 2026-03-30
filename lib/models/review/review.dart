class Review {
  final int id;
  final int productId;
  final int userId;
  final String userName;
  final int rating;
  final String? title;
  final String body;
  final int helpful;
  final List<String> images;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.title,
    required this.body,
    required this.helpful,
    required this.images,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id:        (json['id'] ?? json['_id'] ?? 0) as int,
      productId: (json['product'] ?? 0) as int,
      userId:    (json['user'] ?? 0) as int,
      userName:  json['userName'] as String? ?? 'Anonymous',
      rating:    (json['rating'] ?? 0) as int,
      title:     json['title'] as String?,
      body:      json['body'] as String? ?? '',
      helpful:   (json['helpful'] ?? 0) as int,
      images:    (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ReviewSummary {
  final double avgRating;
  final int totalCount;
  final Map<int, int> ratingBreakdown; // {1: n, 2: n, ...5: n}

  ReviewSummary({
    required this.avgRating,
    required this.totalCount,
    required this.ratingBreakdown,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final raw = (json['ratingBreakdown'] as Map<String, dynamic>?) ?? {};
    return ReviewSummary(
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      totalCount: (json['totalCount'] as int?) ?? 0,
      ratingBreakdown: {
        1: (raw['1'] as int?) ?? 0,
        2: (raw['2'] as int?) ?? 0,
        3: (raw['3'] as int?) ?? 0,
        4: (raw['4'] as int?) ?? 0,
        5: (raw['5'] as int?) ?? 0,
      },
    );
  }

  factory ReviewSummary.empty() => ReviewSummary(
        avgRating: 0,
        totalCount: 0,
        ratingBreakdown: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );
}
