// ignore_for_file: depend_on_referenced_packages, unused_element

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editprofile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  String name = '';
  String rollNo = '';
  String program = 'Select Program';
  String branch = 'Select Branch';
  String semester = '';
  String collegeEmail = '';
  String roomNo = '';
  String phone = '';
  bool mobileVerified = false;
  String? _profileImage;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId != null) {
      // Fetch data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;

        // Check if the profileImage path is valid, if so, load it
        String profileImagePath = userData['profilePic'] ?? '';
        
        setState(() {
          name = userData['name'] ?? '';
          rollNo = userData['rollNo'] ?? '';
          program = userData['program'] ?? 'Select Program';
          branch = userData['branch'] ?? 'Select Branch';
          semester = userData['semester'] ?? '';
          collegeEmail = userData['email'] ?? '';
          roomNo = userData['roomNo'] ?? '';
          phone = userData['phone'] ?? '';

          // Directly use profilePic URL (String)
          _profileImage = profileImagePath; // Store URL (string)
          mobileVerified = userData['mobileVerified'] ?? false;
        });

        // Save data locally in SharedPreferences
        await prefs.setString('name', name);
        await prefs.setString('rollNo', rollNo);
        await prefs.setString('program', program);
        await prefs.setString('branch', branch);
        await prefs.setString('semester', semester);
        await prefs.setString('collegeEmail', collegeEmail);
        await prefs.setString('roomNo', roomNo);
        await prefs.setString('phone', phone);
        await prefs.setString('profileImage', _profileImage ?? '');
        await prefs.setBool('mobileVerified', mobileVerified);
      }
    }
  }

  Widget buildNonEditableField(String label, String value) {
    return TextField(
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      readOnly: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          errorMessage = '';
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
  TextButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EditProfilePage()),
      );
    },
    child: const Text(
      'Edit Profile',
      style: TextStyle(
        color: Color.fromARGB(255, 39, 71, 165), // Ensure the text is visible on AppBar
        fontSize: 16,
      ),
    ),
  ),
],

        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 120.0,
                        height: 160.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle, // Square shape
                          image: _profileImage != null && _profileImage!.isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(_profileImage!),  // Use the URL directly
                            fit: BoxFit.cover,
                          )
                              : const DecorationImage(
                            image: AssetImage('assets/profile_pic.jpg'), // Default local image
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(10.0), // Rounded corners
                        ),
                      ),



                    ],
                  ),
                ),
                const SizedBox(height: 20),
                buildNonEditableField('Name', name),
                const SizedBox(height: 20),
                buildNonEditableField('Roll No.', rollNo),
                const SizedBox(height: 20),
                buildNonEditableField('Program', program),
                const SizedBox(height: 20),
                buildNonEditableField('Branch', branch),
                const SizedBox(height: 20),
                buildNonEditableField('Semester', semester),
                const SizedBox(height: 20),
                buildNonEditableField('College Email', collegeEmail),
                const SizedBox(height: 20),
                buildNonEditableField('Room No.', roomNo),
                const SizedBox(height: 20),
                buildNonEditableField('Phone', phone),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
