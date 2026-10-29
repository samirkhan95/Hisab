import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab/core/providers/firebase_provider.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';

final friendProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userId = ref.watch(currentUserProvider)?.uid;

  if (userId == null) return Stream.value(null);

  return firestore
      .collection('users')
      .where('id', isNotEqualTo: userId)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  });
});
