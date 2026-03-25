import 'package:flutter/material.dart';

import 'notification_item.dart';
import 'notifications_repository.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._repository);
  final NotificationsRepository _repository;

  List<NotificationItem> _items = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationItem> get items => _items;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final (items, unread) = await _repository.fetchNotifications();
      _items = items;
      _unreadCount = unread;
    } catch (_) {
      // Évite une erreur async non gérée au démarrage (API hors ligne, 401, etc.)
      _items = [];
      _unreadCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    await _repository.markRead(id);
    _items = _items
        .map((n) => n.id == id
            ? NotificationItem(
                id: n.id,
                title: n.title,
                message: n.message,
                isRead: true,
                createdAt: n.createdAt,
              )
            : n)
        .toList();
    _unreadCount = _items.where((n) => !n.isRead).length;
    notifyListeners();
  }
}
