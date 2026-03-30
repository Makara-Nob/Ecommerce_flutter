import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/notification/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.tokenKey);
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _notifications = [];
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    final token = await _getToken();
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}?page=$_currentPage&limit=15'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final bodyData = json.decode(response.body);
        final payload = bodyData['data'] ?? {};
        final List<dynamic> list = payload['notifications'] ?? [];
        
        final newNotifications = list.map((item) => NotificationModel.fromJson(item)).toList();
        if (refresh) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }

        _unreadCount = payload['unreadCount'] ?? 0;
        _totalPages = payload['totalPages'] ?? 1;
        _hasMore = _currentPage < _totalPages;
        _currentPage++;
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final token = await _getToken();
    if (token == null) return;

    // Optimistic UI update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        isRead: true,
        createdAt: _notifications[index].createdAt,
        data: _notifications[index].data,
      );
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    try {
      await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.markNotificationRead(id)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final token = await _getToken();
    if (token == null) return;

    // Optimistic UI update
    _notifications = _notifications.map((n) {
      if (!n.isRead) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          body: n.body,
          isRead: true,
          createdAt: n.createdAt,
          data: n.data,
        );
      }
      return n;
    }).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.markAllNotificationsRead}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
