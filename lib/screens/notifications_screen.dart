import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mytank/providers/notification_provider.dart';
import 'package:mytank/models/notification_model.dart';
import 'package:mytank/utilities/constants.dart';

// Helper method to replace deprecated withOpacity
Color withValues(Color color, double opacity) {
  return Color.fromRGBO(
    color.r.toInt(),
    color.g.toInt(),
    color.b.toInt(),
    opacity,
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Real-time connection status indicator
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message:
                      notificationProvider.isSocketConnected
                          ? 'Real-time notifications active'
                          : 'Real-time notifications inactive',
                  child: Icon(
                    notificationProvider.isSocketConnected
                        ? Icons.wifi_rounded
                        : Icons.wifi_off_rounded,
                    color:
                        notificationProvider.isSocketConnected
                            ? Colors.green
                            : Colors.orange,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              if (notificationProvider.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    notificationProvider.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('All notifications marked as read'),
                        backgroundColor: Constants.successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Mark All Read',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        elevation: 0,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return _buildLoadingState();
          }

          if (notificationProvider.error != null) {
            return _buildErrorState(
              notificationProvider.error!,
              notificationProvider,
            );
          }

          if (notificationProvider.notifications.isEmpty) {
            return _buildEmptyState(notificationProvider);
          }

          return _buildNotificationsList(notificationProvider);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(fontSize: 16, color: Constants.greyColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    String error,
    NotificationProvider notificationProvider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Constants.errorColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Constants.errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to Load Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Constants.greyColor),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await notificationProvider.fetchNotifications();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.greyColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(NotificationProvider notificationProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Constants.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: Constants.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Constants.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'re all caught up! No new notifications at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Constants.greyColor),
            ),
            const SizedBox(height: 20),
            // Refresh button to check for new notifications
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await notificationProvider.fetchNotifications();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check for Updates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Test button for adding notifications (development only)
                ElevatedButton.icon(
                  onPressed: () {
                    notificationProvider.addTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Test notification added'),
                        backgroundColor: Constants.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_alert_rounded),
                  label: const Text('Add Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Test button for server format (development only)
            ElevatedButton.icon(
              onPressed: () {
                notificationProvider.addTestNotificationWithServerFormat();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Server format test notification added',
                    ),
                    backgroundColor: Constants.warningColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.cloud_download_rounded),
              label: const Text('Test Server Format'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.warningColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(NotificationProvider notificationProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        // Fetch fresh notifications from the API
        await notificationProvider.fetchNotifications();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notificationProvider.notifications.length,
        itemBuilder: (context, index) {
          final notification = notificationProvider.notifications[index];
          return _buildNotificationCard(notification, notificationProvider);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
    NotificationProvider notificationProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: withValues(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border:
            notification.isRead
                ? null
                : Border.all(
                  color: Constants.primaryColor.withAlpha(50),
                  width: 1,
                ),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            notificationProvider.markAsRead(notification.id);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      notification.isRead
                          ? Constants.greyColor.withAlpha(20)
                          : Constants.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color:
                      notification.isRead
                          ? Constants.greyColor
                          : Constants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                        color:
                            notification.isRead
                                ? Constants.greyColor
                                : Constants.blackColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time and read status
                    Row(
                      children: [
                        Text(
                          notification.getFormattedDate(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Constants.greyColor,
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Constants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
