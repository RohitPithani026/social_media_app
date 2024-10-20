// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/components/my_drawer.dart';
import 'package:social_media_app/components/my_list_tile.dart';
import 'package:social_media_app/components/my_post_button.dart';
import 'package:social_media_app/components/my_textfield.dart';
import 'package:social_media_app/database/firestore.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  // Firestore access
  final FirestoreDatabase database = FirestoreDatabase();

  // Text controller
  final TextEditingController newPostController = TextEditingController();

  // Post message
  void postMessage() {
    // Only post message if there is something in the textfield
    if (newPostController.text.isNotEmpty) {
      String message = newPostController.text;
      database.addPost(message);

      // Clear the controller
      newPostController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("H O M E"),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          // TEXTFIELD FOR USER TO TYPE
          Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                // Textfield
                Expanded(
                  child: MyTextfield(
                    hintText: "Say something..",
                    obscureText: false,
                    controller: newPostController,
                  ),
                ),
                // Post button
                MyPostButton(
                  onTap: postMessage,
                ),
              ],
            ),
          ),

          // POSTS
          StreamBuilder<QuerySnapshot>(
            stream: database.getPostsStream(),
            builder: (context, snapshot) {
              // Show loading circle
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // Check for errors
              if (snapshot.hasError) {
                return Center(
                  child: Text("Error: ${snapshot.error}"),
                );
              }

              // Check if there is no data
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: Text("No posts.. Post something!"),
                  ),
                );
              }

              // Get all posts
              final posts = snapshot.data!.docs;

              // No posts
              if (posts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: Text("No posts.. Post something!"),
                  ),
                );
              }

              // Return posts as a list
              return Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    // Get individual post
                    final post = posts[index];

                    // Get data from each post
                    String message = post['PostMessage'];
                    String userEmail = post['UserEmail'];

                    // Return as a list tile
                    return MyListTile(
                      title: message,
                      subTitle: userEmail,
                    );
                  },
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
