import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';
import '../models/review/review.dart';

class ReviewService {
  final String _base = ApiConstants.baseUrl;

  // GET paginated reviews + summary for a product (public)
  Future<Map<String, dynamic>> getProductReviews(
    int productId, {
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse(
        '$_base/api/v1/public/products/$productId/reviews?page=$page&limit=$limit');

    final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final json = (decoded['data'] != null) ? decoded['data'] : decoded;
      final data = json as Map<String, dynamic>;

      return {
        'reviews': (data['reviews'] as List? ?? [])
            .map((r) => Review.fromJson(r as Map<String, dynamic>))
            .toList(),
        'summary': ReviewSummary.fromJson(data['summary'] as Map<String, dynamic>? ?? {}),
        'totalPages': data['totalPages'] ?? 1,
        'pageNo': data['pageNo'] ?? 1,
      };
    }
    throw Exception('Failed to load reviews: ${response.body}');
  }

  // GET current user's review for a product (auth)
  Future<Review?> getMyReview(int productId, String token) async {
    final uri = Uri.parse('$_base/api/v1/reviews/my/$productId');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final json = (decoded['data'] != null) ? decoded['data'] : decoded;
      final data = json as Map<String, dynamic>;

      if (data['review'] != null) {
        return Review.fromJson(data['review'] as Map<String, dynamic>);
      }
    }
    return null;
  }

  // POST create review (auth) - UPDATED for multipart/images
  Future<Review> createReview({
    required int productId,
    required int rating,
    required String body,
    String? title,
    List<String>? imagePaths, // NEW: local file paths
    required String token,
  }) async {
    final uri = Uri.parse('$_base/api/v1/reviews');
    
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Fields
    request.fields['productId'] = productId.toString();
    request.fields['rating']    = rating.toString();
    request.fields['body']      = body;
    if (title != null && title.isNotEmpty) request.fields['title'] = title;

    // Files
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final path in imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'images',
            stream,
            length,
            filename: path.split('/').last,
            contentType: MediaType('image', 'jpeg'), // Assuming jpeg from picker
          );
          request.files.add(multipartFile);
        }
      }
    }

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 201) {
      // API returns the newly created review in 'data' wrapper (based on Router.ts)
      final decoded = jsonDecode(response.body);
      final reviewJson = (decoded['data'] != null) ? decoded['data'] : decoded;
      return Review.fromJson(reviewJson as Map<String, dynamic>);
    }
    
    final err = jsonDecode(response.body)['message'] ?? 'Failed to create review';
    throw Exception(err);
  }

  // PUT update own review (auth)
  Future<Review> updateReview({
    required int reviewId,
    int? rating,
    String? body,
    String? title,
    required String token,
  }) async {
    final uri = Uri.parse('$_base/api/v1/reviews/$reviewId');
    final payload = <String, dynamic>{};
    if (rating != null) payload['rating'] = rating;
    if (body != null) payload['body'] = body;
    if (title != null) payload['title'] = title;

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return Review.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    final err = jsonDecode(response.body)['message'] ?? 'Failed to update review';
    throw Exception(err);
  }

  // DELETE own review (auth)
  Future<void> deleteReview(int reviewId, String token) async {
    final uri = Uri.parse('$_base/api/v1/reviews/$reviewId');
    final response = await http.delete(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body)['message'] ?? 'Failed to delete review';
      throw Exception(err);
    }
  }
}
