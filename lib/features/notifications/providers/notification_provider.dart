import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab/core/providers/firebase_provider.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';
import '../models/notification_model.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userId = ref.watch(currentUserProvider)?.uid;

  if (userId == null) return Stream.value([]);

  return firestore
      .collection('notifications')
      .where('user_id', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
    final notifications = snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc))
        .toList();

    // Sort manually in memory to bypass the requirement for a composite index
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notifications;
  });
});
