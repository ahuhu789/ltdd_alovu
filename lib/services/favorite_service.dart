import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final User? user = FirebaseAuth.instance.currentUser;

  Stream<bool> favoriteStream(String fieldId) {
    if (user == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(fieldId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<bool> toggleFavorite({
    required String fieldId,
    required Map<String, dynamic> data,
  }) async {
    if (user == null) return false;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(fieldId);

    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
      return false;
    } else {
      await docRef.set({...data, 'favoritedAt': FieldValue.serverTimestamp()});
      return true;
    }
  }
}
