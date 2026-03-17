import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/address/address_model.dart';
import 'storage_service.dart';
import '../constants/api_constants.dart';

class AddressService {
  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse<List<AddressModel>>> getAddresses() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/addresses'),
        headers: headers,
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonResponse['data'] ?? [];
        final addresses = data.map((json) => AddressModel.fromJson(json)).toList();
        return ApiResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Success',
          data: addresses,
        );
      }
      return ApiResponse(success: false, message: jsonResponse['message'] ?? 'Failed to get addresses');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<AddressModel>> createAddress(AddressModel address) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/addresses'),
        headers: headers,
        body: json.encode(address.toJson()),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Address created',
          data: AddressModel.fromJson(jsonResponse['data']),
        );
      }
      return ApiResponse(success: false, message: jsonResponse['message'] ?? 'Failed to create address');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<AddressModel>> updateAddress(int id, AddressModel address) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/addresses/$id'),
        headers: headers,
        body: json.encode(address.toJson()),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Address updated',
          data: AddressModel.fromJson(jsonResponse['data']),
        );
      }
      return ApiResponse(success: false, message: jsonResponse['message'] ?? 'Failed to update address');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<void>> deleteAddress(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/addresses/$id'),
        headers: headers,
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: jsonResponse['message'] ?? 'Address deleted');
      }
      return ApiResponse(success: false, message: jsonResponse['message'] ?? 'Failed to delete address');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<void>> setDefaultAddress(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/addresses/$id/default'),
        headers: headers,
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: jsonResponse['message'] ?? 'Set as default');
      }
      return ApiResponse(success: false, message: jsonResponse['message'] ?? 'Failed to set default');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
