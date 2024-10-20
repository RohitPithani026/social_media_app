// ignore_for_file: unused_catch_stack, use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/components/my_back_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Current logged in user
  User? currentUser = FirebaseAuth.instance.currentUser;

  // Selected image
  File? _image;

  // Fetch user details from Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .get();
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  }

  // Function to upload image to Firebase Storage and update Firestore
  Future<void> _uploadProfilePic() async {
    if (_image == null || currentUser == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Upload the file to Firebase Storage
      String filePath = 'profile_pics/${currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.png';
      UploadTask uploadTask = FirebaseStorage.instance.ref(filePath).putFile(_image!);

      // Get download URL
      String downloadURL = await (await uploadTask).ref.getDownloadURL();

      // Update Firestore with the new profile pic URL
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser!.email)
          .update({'profile_pic': downloadURL});

      setState(() {
        // Clear the image after successful upload
        _image = null;
      });

      Navigator.of(context).pop(); // Hide loading indicator

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture uploaded successfully!')),
      );
    } catch (e, stackTrace) {
      Navigator.of(context).pop(); // Hide loading indicator

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: $e')),
      );
    }
  }

  // Function to remove the profile picture
  Future<void> _removeProfilePic() async {
    if (currentUser == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch current profile pic URL
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser!.email)
          .get();
      String? profilePicUrl = userDoc.get('profile_pic');

      if (profilePicUrl != null) {
        // Remove the file from Firebase Storage
        await FirebaseStorage.instance.refFromURL(profilePicUrl).delete();

        // Update Firestore to remove the profile pic URL
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(currentUser!.email)
            .update({'profile_pic': FieldValue.delete()});
      }

      setState(() {
        _image = null;
      });

      Navigator.of(context).pop(); // Hide loading indicator

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture removed successfully!')),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Hide loading indicator

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing profile picture: $e')),
      );
    }
  }

  // Handle the selection from the dropdown menu
  void _handleMenuSelection(String choice) {
    if (choice == 'Change Profile Picture') {
      _pickImage();
    } else if (choice == 'Remove Profile Picture') {
      _removeProfilePic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          } else if (snapshot.hasData) {
            Map<String, dynamic>? user = snapshot.data!.data();

            return Center(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 50, left: 25),
                    child: Row(
                      children: [
                        MyBackButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  GestureDetector(
                    onTap: () => _pickImage(),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.all(25),
                          child: _image != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.cover,
                              width: 64,
                              height: 64,
                            ),
                          )
                              : user?['profile_pic'] != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              user!['profile_pic'],
                              fit: BoxFit.cover,
                              width: 64,
                              height: 64,
                            ),
                          )
                              : const Icon(
                            Icons.person,
                            size: 64,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: PopupMenuButton<String>(
                            onSelected: _handleMenuSelection,
                            itemBuilder: (BuildContext context) {
                              return {'Change Profile Picture', 'Remove Profile Picture'}
                                  .map((String choice) {
                                return PopupMenuItem<String>(
                                  value: choice,
                                  child: Text(choice),
                                );
                              }).toList();
                            },
                            icon: const Icon(Icons.more_vert),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_image != null)
                    ElevatedButton(
                      onPressed: _uploadProfilePic,
                      child: const Text('Upload Profile Picture'),
                    ),
                  const SizedBox(height: 25),
                  Text(
                    user!['username'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user['email'],
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Text("No data");
          }
        },
      ),
    );
  }
}
