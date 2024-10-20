import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDatabase {
  // current logged in user
  User? user = FirebaseAuth.instance.currentUser;

  // get collection of posts from firebase
  final CollectionReference posts = FirebaseFirestore.instance.collection('Posts');

  // post a message
  Future<String> addPost(String message) async {
    if (user == null) {
      return 'User not authenticated';
    }

    try {
      await posts.add({
        'UserEmail': user!.email,
        'PostMessage': message,
        'TimeStamp': Timestamp.now(),
      });
      return 'Post added successfully';
    } catch (e) {
      return 'Failed to add post: $e';
    }
  }

  // read posts from database
  Stream<QuerySnapshot> getPostsStream() {
    final postsStream = posts.orderBy('TimeStamp').snapshots();
    return postsStream;
  }
}
