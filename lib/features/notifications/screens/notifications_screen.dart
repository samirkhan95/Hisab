import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:hisab/core/widgets/avatar.dart';
import 'package:hisab/features/home/providers/friend_provider.dart';
import 'package:hisab/core/services/haptic_service.dart';

import 'package:hisab/core/providers/firebase_provider.dart';
import 'package:hisab/core/constants.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final friendAsync = ref.watch(friendProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticService.medium();
          await ref.refresh(notificationsProvider.future);
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No notifications yet.')),
                ],
              );
            }
            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 6,
              radius: const Radius.circular(10),
              interactive: true,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final timeStr =
                      DateFormat('MMM dd, hh:mm a').format(notification.createdAt.toLocal());

                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    onUpdate: (details) {
                      if (details.reached && !details.previousReached) {
                        HapticService.light();
                      }
                    },
                    background: Container(
                      color: AppColors.alert,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 28),
                    ),
                    onDismissed: (direction) async {
                      HapticService.heavy();
                      final firestore = ref.read(firestoreProvider);
                      await firestore
                          .collection('notifications')
                          .doc(notification.id)
                          .delete();
                    },
                    child: Column(
                      children: [
                        ListTile(
                          leading: Avatar(
                            imageUrl: friendAsync.value?['avatar_url'],
                            radius: 20,
                          ),
                          title: Text(
                            notification.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.body),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                        Divider(
                          height: 32,
                          thickness: 0.5,
                          indent: 70,
                          endIndent: 24,
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
