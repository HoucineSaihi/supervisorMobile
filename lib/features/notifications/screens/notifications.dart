import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supervisormobile/features/notifications/dtos/notification_dto.dart';
import 'package:supervisormobile/features/notifications/notification_controller.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final NotificationController controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController(), permanent: true);
    controller.loadNotifications();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifTitle),
        actions: [
          Obx(() => TextButton(
                onPressed: controller.unreadCount.value > 0 ? controller.markAllRead : null,
                child: Text(l10n.notifMarkAllRead),
              )),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Obx(() => Tab(text: '${l10n.notifUnreadTab} (${controller.unreadCount.value})')),
            Tab(text: l10n.notifArchivedTab),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return TabBarView(
          controller: _tabController,
          children: [
            _NotificationList(
              items: controller.unread,
              emptyText: l10n.notifEmptyUnread,
              onRefresh: controller.loadNotifications,
              onMarkRead: controller.markRead,
              showMarkReadButton: true,
            ),
            _NotificationList(
              items: controller.archived,
              emptyText: l10n.notifEmptyArchived,
              onRefresh: controller.loadNotifications,
              onMarkRead: controller.markRead,
              showMarkReadButton: false,
            ),
          ],
        );
      }),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.items,
    required this.emptyText,
    required this.onRefresh,
    required this.onMarkRead,
    required this.showMarkReadButton,
  });

  final List<NotificationItemDto> items;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final void Function(int id) onMarkRead;
  final bool showMarkReadButton;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Center(child: Text(emptyText)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return _NotificationTile(
            item: item,
            onMarkRead: showMarkReadButton ? () => onMarkRead(item.id) : null,
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, this.onMarkRead});

  final NotificationItemDto item;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRejection = item.type == NotificationKind.executionRejected;
    return ListTile(
      leading: Icon(
        isRejection ? Icons.error_outline : Icons.check_circle_outline,
        color: isRejection ? TColors.error : TColors.primary,
      ),
      title: Text(
        item.title,
        style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.body),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM HH:mm').format(item.createdAt.toLocal()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      isThreeLine: true,
      trailing: onMarkRead == null
          ? null
          : IconButton(
              icon: const Icon(Icons.check_circle_outline, size: 22),
              color: TColors.primary,
              tooltip: l10n.notifMarkReadTooltip,
              onPressed: onMarkRead,
            ),
    );
  }
}
