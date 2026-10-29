import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab/core/providers/firebase_provider.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';
import 'package:hisab/features/messages/models/messages_model.dart';

final messagesProvider = StreamProvider<List<Message>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userId = ref.watch(currentUserProvider)?.uid;

  if (userId == null) return Stream.value([]);

  return firestore
      .collection('messages')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
});
