import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hisab/core/providers/firebase_provider.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';

final profileProvider = StreamProvider<Map<String, dynamic>?>((ref) async* {
  final firestore = ref.watch(firestoreProvider);
  final userId = ref.watch(currentUserProvider)?.uid;

  if (userId == null) {
    yield null;
    return;
  }

  // 1. Try to yield cached data first
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'profile_$userId';
  final cachedStr = prefs.getString(cacheKey);
  if (cachedStr != null) {
    yield json.decode(cachedStr) as Map<String, dynamic>;
  }

  // 2. Stream from Firestore and update cache
  yield* firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
        if (snapshot.exists) {
          final profile = snapshot.data()!;
          prefs.setString(cacheKey, json.encode(profile));
          return profile;
        }
        return null;
      });
});

final allProfilesProvider = StreamProvider<Map<String, Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore.collection('users').snapshots().map((snapshot) {
    final Map<String, Map<String, dynamic>> map = {};
    for (final doc in snapshot.docs) {
      map[doc.id] = doc.data();
    }
    return map;
  });
});
