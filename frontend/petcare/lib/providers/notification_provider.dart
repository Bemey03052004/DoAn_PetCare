import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service;
  NotificationProvider(this._service);

  List<AppNotification> _items = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.getMyNotifications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    await _service.markRead(id);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = AppNotification(
        id: _items[idx].id,
        userId: _items[idx].userId,
        title: _items[idx].title,
        body: _items[idx].body,
        isRead: true,
        createdAt: _items[idx].createdAt,
      );
      notifyListeners();
    }
  }
}


