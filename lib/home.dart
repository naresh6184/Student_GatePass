import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:new_gatepass_app/emergency_gatepass_generation.dart';
import 'package:new_gatepass_app/past_gatepasses.dart';
import 'package:new_gatepass_app/rejected_gatepasses.dart';
import 'package:new_gatepass_app/update_expired_status.dart';
import 'package:new_gatepass_app/vacation_gatepass_generation.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';
import 'out_gatepass_generation.dart';
import 'login.dart'; // Import the login screen
import 'local_gatepass_generation.dart';
import 'saved_gatepasses.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gatepass_display.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = ''; // To store the user's name
  bool isLoading = true; // Loading state for fetching user data and gate passes
  String? _profileImage;
  List<Map<String, dynamic>> activeGatePasses =
      []; // List to hold active gate passes


  Future<void> _refreshHomepage() async {
    print("refreshed Home Page Successfully.");
    await checkAndUpdateExpiredGatePasses();
    await _fetchUserData();
    await _fetchActiveGatePasses();
  }

  // Fetch the user's data from Firestore to get the name
  Future<void> _fetchUserData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
// Check if the profileImage path is valid, if so, load it
      String profileImagePath = userSnapshot['profilePic'] ?? '';

      if (userSnapshot.exists) {
        setState(() {
          _profileImage = profileImagePath; // Store URL (string)
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog("Error fetching user data: $e");
    }
  }

  // Fetch active gate passes where `out` == 1 and `in` == 0
  Future<void> _fetchActiveGatePasses() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final gatePassesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('GatePasses')
          .where('expired',isEqualTo: false)
          .where('out', isEqualTo: 1) // Use integer if stored as integer
          .where('in', isEqualTo: 0) // Filter gate passes not yet returned
          .get();

      List<Map<String, dynamic>> gatePasses = gatePassesSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      setState(() {
        activeGatePasses = gatePasses;
      });
    } catch (e) {
      _showErrorDialog("Error fetching active gate passes: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: ()  {
              Navigator.pop(context);
              _refreshHomepage();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Function to log out the user
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs
        .clear(); // This clears all the saved preferences (including login data)

    // After clearing the data, navigate to the login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => const LoginPage()), // Navigate to LoginPage
      (route) => false, // Remove all routes to prevent back navigation
    );
  }


  @override
  void initState() {
    super.initState();
    _refreshHomepage();
  }




  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final List<Map<String, dynamic>> filteredGatePasses = activeGatePasses
        .where((gatePass) => gatePass['out'] == "1" && gatePass['in'] == "0")
        .toList(); // Filter gate passes once
    return Scaffold(
      appBar: AppBar(
        title: const Text('DashBoard'),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 20, // Set the size of the profile picture
              backgroundImage:
                  _profileImage != null && _profileImage!.isNotEmpty
                      ? NetworkImage(
                          _profileImage!) // Use network image if available
                      : AssetImage('assets/profile_pic.jpg')
                          as ImageProvider, // Default image if no profile pic
            ),
            onPressed: () async {
             String refresh =  await  Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
             if(refresh =="refresh")
               {
                 _refreshHomepage();
               }
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context); // Call the logout function
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body:
      Padding(
        padding: const EdgeInsets.all(16.0),
        child:
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Active Gate Passes Section
              Center(
                child: Text(
                  'Active Gate Pass',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 10), // Add some spacing

              // Display active gate passes if any (use a ListView for dynamic content)
              if (activeGatePasses.isEmpty)
                const Center(
                  child: Text('No active gate passes available.'),
                )
              else
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.12, // Set a specific height
                  child: ListView.builder(
                    itemCount: activeGatePasses.length,
                    itemBuilder: (context, index) {
                      final gatePass = activeGatePasses[index];
                      return Card(
                        color: Colors.blue[50],
                        child: ListTile(
                          title: Text('Place: ${gatePass['place']}'),
                          subtitle: Text(
                            'Expires: ${gatePass['timeIn'] != null ? DateFormat('hh:mm a, dd MMM. yyyy').format((gatePass['timeIn'] as Timestamp).toDate()) : 'N/A'}',
                          ),
                          onTap: () async {
                            // Navigate to GatePassDisplay with the correct gatePassId
                            String refresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GatePassDisplay(
                                  GatePassId: gatePass['id'],
                                  activegatepass: true, // Pass the gatepassid to display
                                ),
                              ),
                            );
                            if (refresh == "refresh") {
                              _refreshHomepage();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),

              // Gate pass generation buttons
              Center(
                child: Text(
                  'Gate Pass Generation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 10), // Add some spacing

              // Generation buttons
              Column(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () async {
                      String refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OutGatePassPage()),
                      );
                      if (refresh == "refresh") {
                        _refreshHomepage();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(
                        double.infinity,
                        MediaQuery.of(context).size.height * 0.06,
                      ),
                    ),
                    child: const Text(
                      'Out Station Gate Pass',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () async {
                      String refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LocalGatePassPage()),
                      );
                      if (refresh == "refresh") {
                        _refreshHomepage();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(
                        double.infinity,
                        MediaQuery.of(context).size.height * 0.06,
                      ),
                    ),
                    child: const Text(
                      'Local Gate Pass',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () async {
                      String refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VacationGatePassPage()),
                      );
                      if (refresh == "refresh") {
                        _refreshHomepage();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(
                        double.infinity,
                        MediaQuery.of(context).size.height * 0.06,
                      ),
                    ),
                    child: const Text(
                      'Vacation Gate Pass',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () async {
                      String refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmergencyGatePassPage()),
                      );
                      if (refresh == "refresh") {
                        _refreshHomepage();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(
                        double.infinity,
                        MediaQuery.of(context).size.height * 0.06,
                      ),
                    ),
                    child: const Text(
                      'Emergency Gate Pass',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // More buttons for upcoming and past gate passes
              Center(
                child: Text(
                  'Other Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 10), // Add some spacing

              Column(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () async {
                      String refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UpcomingGatePassesPage()),
                      );
                      if (refresh == "refresh") {
                        _refreshHomepage();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(
                        double.infinity,
                        MediaQuery.of(context).size.height * 0.06,
                      ),
                    ),
                    child: const Text(
                      'View Saved Gate Passes',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () async {
                      String refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PastGatePassesPage()),
                      );
                      if (refresh == "refresh") {
                        _refreshHomepage();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(
                        double.infinity,
                        MediaQuery.of(context).size.height * 0.06,
                      ),
                    ),
                    child: const Text(
                      'Past Gate Pass Record',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () async {
                      String refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RejectedGatePassesPage()),
                      );
                      if (refresh == "refresh") {
                        _refreshHomepage();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(
                        double.infinity,
                        MediaQuery.of(context).size.height * 0.06,
                      ),
                    ),
                    child: const Text(
                      'Rejected Gate Passes',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        ,
      ),
    );
  }
}
