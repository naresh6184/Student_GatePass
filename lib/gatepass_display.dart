// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add this for formatting

// ignore: must_be_immutable
class GatePassDisplay extends StatelessWidget {
  // ignore: non_constant_identifier_names
  final String GatePassId;
  final bool activegatepass;
String uniqueid = ''; 
  GatePassDisplay({
    super.key,
    // ignore: non_constant_identifier_names
    required this.GatePassId,
    this.activegatepass=false,
  });

  // ignore: non_constant_identifier_names
  String? USERID;
  String? _profileImage;

  // Fetch GatePass and User data from Firestore
  Future<Map<String, dynamic>?> fetchGatePassData() async {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  USERID = userId;
  // Initialize the UniqueId variable
  try {
    // First, try to fetch GatePass data by UniqueId
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('GatePasses')
        .where('UniqueId', isEqualTo: GatePassId)
        .get();

    // If no document found with UniqueId, search by Document ID
    if (querySnapshot.docs.isEmpty) {
      uniqueid = GatePassId; // Set UniqueId to GatePassId if found by UniqueId
      querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('GatePasses')
          .get();

      // Loop through the documents to find a match by Document ID
      for (var doc in querySnapshot.docs) {
        if (doc.id == GatePassId) {
          querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('GatePasses')
              .where(FieldPath.documentId, isEqualTo: GatePassId)
              .get();
          break; // Exit loop once document is found
        }
      }
    }

    // If document found either by UniqueId or Document ID
    if (querySnapshot.docs.isNotEmpty) {
      final gatePassData = querySnapshot.docs.first.data();

      // Fetch user data
      final userDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
// Check if the profileImage path is valid, if so, load it
      _profileImage = userDocSnapshot['profilePic'] ?? '';

      if (userDocSnapshot.exists) {
        // Add user data to the gatePass data
        uniqueid = gatePassData['UniqueId'] ?? ''; // Extract UniqueId from document if found by doc ID
        gatePassData['userData'] = userDocSnapshot.data();
        return gatePassData;
      } else {
        print("User data not found.");
        return null;
      }
    } else {
      print("No document found with GatePassId: $GatePassId");
      return null;
    }
  } catch (e) {
    print("Error fetching data: $e");
    return null;
  }
}

  // Format DateTime as "10:00 PM, 15 Nov. 2024"
  String formatDateTime(DateTime dateTime) {
    return DateFormat("h:mm a, dd MMM. yyyy").format(dateTime);
  }

  // Safe getter for String fields
  String _safeString(String? value) {
    return value ?? "N/A"; // If the value is null, return "N/A"
  }

  // Safe getter for DateTime fields
  String _safeDateTime(DateTime? dateTime) {
    return dateTime != null ? formatDateTime(dateTime) : "N/A"; // Format DateTime or return "N/A"
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.05;
    final qrSize = screenSize.width * 0.5;

    return Scaffold(
      appBar: AppBar(
          leading: IconButton(onPressed: (){
            Navigator.pop(context,"refresh");
          }, icon:Icon(Icons.arrow_back)),
          title: const Text("Gate Pass")),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: fetchGatePassData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text("Error loading gate pass data.");
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Text("Gate pass not found.");
              }

              final gatePassData = snapshot.data!;
              final userData = gatePassData['userData'];
              final timeOut = (gatePassData['timeOut'] as Timestamp?)?.toDate();
              final timeIn = (gatePassData['timeIn'] as Timestamp?)?.toDate();

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display the QR Code with the provided GatePassId
                  QrImageView(
                    data: uniqueid,
                    version: QrVersions.auto,
                    size: qrSize,
                  ),
                  SizedBox(height: screenSize.height * 0.03),

                  // Display user and gate pass details in left-right format
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRow("Name:", _safeString(userData['name'])),
                        _buildRow("Roll No.:", _safeString(userData['rollNo'])),
                        _buildRow("Time Out:", _safeDateTime(timeOut)),
                        _buildRow("Time In:", _safeDateTime(timeIn)),
                        _buildRow("Purpose:", _safeString(gatePassData['purpose'])),
                        _buildRow("Place:", _safeString(gatePassData['place'])),
                        _buildRow("Contact No.:", _safeString(userData['phone'])),
                      ],
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.02),

                  Container(
                    width: screenSize.width * 0.4, // Adjust width dynamically
                    height: screenSize.width * 0.5, // Adjust height dynamically
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle, // Square shape
                      image: _profileImage != null && _profileImage!.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(_profileImage!), // Use the profile picture URL
                        fit: BoxFit.cover,
                      )
                          : const DecorationImage(
                        image: AssetImage('assets/photo.png'), // Default placeholder
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(10.0), // Rounded corners
                      border: Border.all(
                        color: Colors.grey.shade300, // Optional border
                        width: 2.0,
                      ),
                    ),
                  ),


                  // Okay Button to go back to the Home page
                  SizedBox(height: screenSize.height * 0.02),
                  ElevatedButton(
              style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              ),),
                    onPressed: () {
                      if(activegatepass)
                        {
                          Navigator.pop(context,"refresh");
                        }
                      else
                        {
                          Navigator.pop(context ,"refresh");
                          Navigator.pop(context ,"refresh");

                        }

                    },
                    child: const Text("Okay",style: TextStyle(fontSize: 20),),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper method to build rows with labels and values
  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120, // Width for the label
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
