import 'package:flutter/material.dart';
import '../models/address/address_model.dart';
import '../services/address_service.dart';

class AddressProvider with ChangeNotifier {
  final AddressService _addressService = AddressService();
  
  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _error;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  Future<void> loadAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _addressService.getAddresses();
      if (response.success && response.data != null) {
        _addresses = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAddress(AddressModel address) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _addressService.createAddress(address);
      if (response.success && response.data != null) {
        if (response.data!.isDefault) {
           // update others to not default locally
           for (int i = 0; i < _addresses.length; i++) {
             _addresses[i] = AddressModel(
               id: _addresses[i].id,
               title: _addresses[i].title,
               recipientName: _addresses[i].recipientName,
               phoneNumber: _addresses[i].phoneNumber,
               streetAddress: _addresses[i].streetAddress,
               city: _addresses[i].city,
               state: _addresses[i].state,
               zipCode: _addresses[i].zipCode,
               isDefault: false
             );
           }
        }
        _addresses.insert(0, response.data!);
        _error = null;
        notifyListeners();
        return true;
      }
      _error = response.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress(int id, AddressModel address) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _addressService.updateAddress(id, address);
      if (response.success && response.data != null) {
        final index = _addresses.indexWhere((a) => a.id == id);
        if (index != -1) {
          if (response.data!.isDefault) {
             for (int i = 0; i < _addresses.length; i++) {
               if (i != index) {
                 _addresses[i] = AddressModel(
                   id: _addresses[i].id,
                   title: _addresses[i].title,
                   recipientName: _addresses[i].recipientName,
                   phoneNumber: _addresses[i].phoneNumber,
                   streetAddress: _addresses[i].streetAddress,
                   city: _addresses[i].city,
                   state: _addresses[i].state,
                   zipCode: _addresses[i].zipCode,
                   isDefault: false
                 );
               }
             }
          }
          _addresses[index] = response.data!;
        }
        _error = null;
        notifyListeners();
        return true;
      }
      _error = response.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAddress(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _addressService.deleteAddress(id);
      if (response.success) {
        _addresses.removeWhere((a) => a.id == id);
        // If we deleted the default, fetch cleanly from server to get new correct state
        if (!_addresses.any((a) => a.isDefault) && _addresses.isNotEmpty) {
           await loadAddresses();
           return true;
        }
        _error = null;
        notifyListeners();
        return true;
      }
      _error = response.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultAddress(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _addressService.setDefaultAddress(id);
      if (response.success) {
        for (int i = 0; i < _addresses.length; i++) {
          final isTarget = _addresses[i].id == id;
          _addresses[i] = AddressModel(
            id: _addresses[i].id,
            title: _addresses[i].title,
            recipientName: _addresses[i].recipientName,
            phoneNumber: _addresses[i].phoneNumber,
            streetAddress: _addresses[i].streetAddress,
            city: _addresses[i].city,
            state: _addresses[i].state,
            zipCode: _addresses[i].zipCode,
            isDefault: isTarget
          );
        }
        _error = null;
        notifyListeners();
        return true;
      }
      _error = response.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _addresses = [];
    _error = null;
    notifyListeners();
  }
}
