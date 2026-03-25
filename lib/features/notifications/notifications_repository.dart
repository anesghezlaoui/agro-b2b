import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'notification_item.dart';

class NotificationsRepository {
  NotificationsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<(List<NotificationItem>, int)> fetchNotifications() async {
    final json = await _apiClient.getJson(ApiEndpoints.notifications);
    final raw = (json['results'] as List?) ?? <dynamic>[];
    final unread = (json['unread_count'] as num?)?.toInt() ?? 0;
    final items =
        raw.whereType<Map<String, dynamic>>().map(NotificationItem.fromJson).toList();
    return (items, unread);
  }

  Future<void> markRead(int id) async {
    await _apiClient.postJson('${ApiEndpoints.notifications}/$id/read');
  }
}
