import 'package:get/get.dart';
import 'package:supervisormobile/features/notifications/dtos/notification_dto.dart';
import 'package:supervisormobile/services/DioService.dart';

class NotificationController extends GetxController {
  final RxList<NotificationItemDto> notifications = <NotificationItemDto>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  List<NotificationItemDto> get unread =>
      notifications.where((n) => !n.isRead).toList();

  /// "Archived" = already-read notifications.
  List<NotificationItemDto> get archived =>
      notifications.where((n) => n.isRead).toList();

  Future<void> loadNotifications() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final response = await DioService.dio.get('/Notification');
      final data = response.data as Map<String, dynamic>;
      final items = (data['notifications'] as List<dynamic>? ?? [])
          .map((json) => NotificationItemDto.fromJson(json as Map<String, dynamic>))
          .toList();
      notifications.assignAll(items);
      unreadCount.value = data['unreadCount'] as int? ?? 0;
    } catch (e) {
      print('❌ NotificationController: failed to load notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount.value == 0) return;
    try {
      await DioService.dio.post('/Notification/mark-read');
      _applyRead(notifications.map((n) => n.id).toSet());
      unreadCount.value = 0;
    } catch (e) {
      print('❌ NotificationController: failed to mark notifications as read: $e');
    }
  }

  Future<void> markRead(int id) async {
    final target = notifications.firstWhereOrNull((n) => n.id == id);
    if (target == null || target.isRead) return;
    try {
      await DioService.dio.post('/Notification/mark-read', queryParameters: {'id': id});
      _applyRead({id});
      if (unreadCount.value > 0) unreadCount.value -= 1;
    } catch (e) {
      print('❌ NotificationController: failed to mark notification $id as read: $e');
    }
  }

  void _applyRead(Set<int> ids) {
    notifications.assignAll(notifications.map((n) {
      if (!ids.contains(n.id) || n.isRead) return n;
      return NotificationItemDto(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        campaignId: n.campaignId,
        siteId: n.siteId,
        executionId: n.executionId,
        submissionId: n.submissionId,
        isRead: true,
        createdAt: n.createdAt,
      );
    }));
  }

  /// Called when a SignalR push arrives while the app is open, so the badge
  /// reflects it immediately without waiting for the next full reload.
  void onRealtimeNotificationReceived() {
    unreadCount.value += 1;
    loadNotifications();
  }
}
