import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/api_response.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': ApiConstants.contentTypeJson,
    };

    if (includeAuth) {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        print('🔑 ApiService: Retrieved token: ${token.length > 20 ? token.substring(0, 20) : token}... (${token.length} chars)');
        headers[ApiConstants.authorizationHeader] =
            '${ApiConstants.bearerPrefix} $token';
        print('📤 ApiService: Auth header set with Bearer token');
      } else {
        print('⚠️ ApiService: No token found in storage');
      }
    }

    return headers;
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: requiresAuth);

      print('📤 ApiService: GET request to $endpoint');
      final response = await http.get(url, headers: headers).timeout(
        ApiConstants.requestTimeout,
        onTimeout: () {
          throw const SocketException('Connection timed out');
        },
      );
      return _handleResponse<T>(response, fromJson, endpoint);
    } on SocketException catch (e) {
      print('❌ ApiService: SocketException for $endpoint - $e');
      return ApiResponse<T>(
        success: false,
        message: 'No internet connection',
        error: e.toString(),
      );
    } catch (e) {
      print('💥 ApiService: Exception for $endpoint - $e');
      return ApiResponse<T>(
        success: false,
        message: 'An error occurred: $e',
        error: e.toString(),
      );
    }
  }

  // Generic GET LIST request
  Future<ApiResponse<List<T>>> getList<T>(
    String endpoint, {
    bool requiresAuth = true,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: requiresAuth);

      print('📤 ApiService: GET (List) request to $endpoint');
      final response = await http.get(url, headers: headers).timeout(
        ApiConstants.requestTimeout,
        onTimeout: () {
          throw const SocketException('Connection timed out');
        },
      );

      return _handleResponseList<T>(response, fromJson, endpoint);
    } on SocketException catch (e) {
      print('❌ ApiService: SocketException for $endpoint - $e');
      return ApiResponse<List<T>>(
        success: false,
        message: 'No internet connection',
        error: e.toString(),
      );
    } catch (e) {
      print('💥 ApiService: Exception for $endpoint - $e');
      return ApiResponse<List<T>>(
        success: false,
        message: 'An error occurred: $e',
        error: e.toString(),
      );
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: requiresAuth);
      print('📤 ApiService: POST request to $endpoint');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(
        ApiConstants.requestTimeout,
        onTimeout: () {
          throw const SocketException('Connection timed out');
        },
      );

      return _handleResponse<T>(response, fromJson, endpoint);
    } on SocketException catch (e) {
      print('❌ ApiService: SocketException for $endpoint - $e');
      return ApiResponse<T>(
        success: false,
        message: 'No internet connection',
        error: e.toString(),
      );
    } catch (e) {
      print('💥 ApiService: Exception for $endpoint - $e');
      return ApiResponse<T>(
        success: false,
        message: 'An error occurred: $e',
        error: e.toString(),
      );
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      var url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      
      if (queryParams != null) {
        url = url.replace(queryParameters: queryParams);
      }
      
      final headers = await _getHeaders(includeAuth: requiresAuth);
      print('📤 ApiService: PUT request to $endpoint');

      final response = await http.put(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        ApiConstants.requestTimeout,
        onTimeout: () {
          throw const SocketException('Connection timed out');
        },
      );

      return _handleResponse<T>(response, fromJson, endpoint);
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        message: 'No internet connection',
        error: 'Network error',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'An error occurred: $e',
        error: e.toString(),
      );
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: requiresAuth);
      print('📤 ApiService: DELETE request to $endpoint');

      final response = await http.delete(url, headers: headers).timeout(
        ApiConstants.requestTimeout,
        onTimeout: () {
          throw const SocketException('Connection timed out');
        },
      );
      return _handleResponse<T>(response, fromJson, endpoint);
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        message: 'No internet connection',
        error: 'Network error',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'An error occurred: $e',
        error: e.toString(),
      );
    }
  }

  // File Upload request
  Future<ApiResponse<String>> uploadFile(File file) async {
    try {
      final endpoint = '/api/v1/files/upload';
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', url);
      print('📤 ApiService: File Upload request to $endpoint');
      
      // Add headers (Auth)
      final headers = await _getHeaders(includeAuth: true);
      request.headers.addAll(headers);
      
      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final length = await file.length();
      
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: file.path.split('/').last,
      );
      
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send().timeout(
        ApiConstants.uploadTimeout,
        onTimeout: () {
          throw const SocketException('Connection timed out');
        },
      );
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse<String>(response, null, endpoint);
    } on SocketException {
      return ApiResponse<String>(
        success: false,
        message: 'No internet connection',
        error: 'Network error',
      );
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        message: 'An error occurred: $e',
        error: e.toString(),
      );
    }
  }

  // Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
    String endpoint,
  ) {
    try {
      print('📥 ApiService: Response status ${response.statusCode}');
      print('📦 ApiService: Response body: ${response.body}');
      final jsonResponse = jsonDecode(response.body);

      // Check for success either via boolean 'success' or string 'status'
      bool isSuccess = false;
      if (jsonResponse.containsKey('success')) {
        isSuccess = jsonResponse['success'] == true;
      } else if (jsonResponse.containsKey('status')) {
        final status = jsonResponse['status'];
        isSuccess = status == 'success' || status == 'SUCCESS' || status == 'OK' || status == 200;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (isSuccess) {
            print('✅ ApiService: Success response for $endpoint');
            return ApiResponse<T>.fromJson(jsonResponse, fromJson);
        } else {
            print('❌ ApiService: Error response for $endpoint - ${jsonResponse['message']} (Status: ${jsonResponse['status']})');
            return ApiResponse<T>(
              success: false,
              message: jsonResponse['message'] ?? 'Request failed',
              error: jsonResponse['error'] ?? 'Unknown error',
            );
        }
      } else {
        print('❌ ApiService: Error response - ${jsonResponse['message']}');
        return ApiResponse<T>(
          success: false,
          message: jsonResponse['message'] ?? 'Request failed',
          error: jsonResponse['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      print('💥 ApiService: Failed to parse response - $e');
      return ApiResponse<T>(
        success: false,
        message: 'Failed to parse response',
        error: e.toString(),
      );
    }
  }

  // Handle HTTP response for Lists
  ApiResponse<List<T>> _handleResponseList<T>(
    http.Response response,
    T Function(dynamic) fromJson,
    String endpoint,
  ) {
    try {
      print('📥 ApiService: Response status ${response.statusCode}');
      print('📦 ApiService: Response body: ${response.body}');
      final jsonResponse = jsonDecode(response.body);

      bool isSuccess = false;
      if (jsonResponse.containsKey('success')) {
        isSuccess = jsonResponse['success'] == true;
      } else if (jsonResponse.containsKey('status')) {
        final status = jsonResponse['status'];
        isSuccess = status == 'success' || status == 'SUCCESS' || status == 'OK' || status == 200;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (isSuccess && jsonResponse['data'] != null) {
          final List<dynamic> dataList = jsonResponse['data'] is List ? jsonResponse['data'] : [];
          final List<T> items = dataList.map((item) => fromJson(item)).toList();
          print('✅ ApiService: Success response for $endpoint (Found ${items.length} items)');
          return ApiResponse<List<T>>(
            success: true,
            message: jsonResponse['message'] ?? 'Success',
            data: items,
          );
        } else {
             print('❌ ApiService: Error response for $endpoint - ${jsonResponse['message']}');
             return ApiResponse<List<T>>(
              success: false,
              message: jsonResponse['message'] ?? 'Request failed',
              error: jsonResponse['error'],
             );
        }
      } else {
        print('❌ ApiService: Error response for $endpoint - ${response.statusCode}');
        return ApiResponse<List<T>>(
          success: false,
          message: jsonResponse['message'] ?? 'Request failed',
          error: jsonResponse['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      print('💥 ApiService: Failed to parse list response for $endpoint - $e');
      return ApiResponse<List<T>>(
        success: false,
        message: 'Failed to parse response',
        error: e.toString(),
      );
    }
  }
}
