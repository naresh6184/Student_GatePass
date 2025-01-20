import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'gatepass_display.dart'; // Import GatePassDisplay widget

class UpcomingGatePassesPage extends StatefulWidget {
  const UpcomingGatePassesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UpcomingGatePassesPageState createState() => _UpcomingGatePassesPageState();
}

class _UpcomingGatePassesPageState extends State<UpcomingGatePassesPage> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  Stream<List<DocumentSnapshot>> getFilteredGatePasses(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('GatePasses')
        .where('timeIn', isGreaterThan: Timestamp.now()) // Upcoming gate passes
        .snapshots()
        .map((snapshot) {
      // Filter documents locally
      return snapshot.docs.where((doc) {
        final data = doc.data();
        if (data['gatepassType'] == "LOCAL") {
          // For LOCAL gatepasses, check only 'expired'
          return data['expired'] == false;
        } else {
          // For other gatepasses, check both 'expired' and 'request'
          return data['expired'] == false && data['request'] == 1;
        }

      }).toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.pop(context,"refresh");
        }, icon:Icon(Icons.arrow_back)),
        title: const Text("Saved Gate Passes"),
      ),
      body: userId == null
          ? const Center(child: Text("User not logged in"))


          : StreamBuilder<List<DocumentSnapshot>>(
        stream: getFilteredGatePasses(userId!), // Modified stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error fetching data: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No upcoming gate passes"));
          }

          // Use the filtered list
          final gatePassDocs = snapshot.data!;
          return ListView.builder(
            itemCount: gatePassDocs.length,
            itemBuilder: (context, index) {
              final doc = gatePassDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              // Extract details
              final String gatePassId = data['UniqueId'] ?? 'No ID available';
              final Timestamp? timeIn = data['timeIn'];
              final Timestamp? timeOut = data['timeOut'];
              final String purpose = data['purpose'] ?? 'No purpose';
              final String gatePassType = data['gatepassType'] ?? 'Unknown';

              // Format times
              final String formattedTimeIn = timeIn != null
                  ? DateFormat('hh:mm a, dd MMM. yyyy').format(timeIn.toDate())
                  : 'No time in set';
              final String formattedTimeOut = timeOut != null
                  ? DateFormat('hh:mm a, dd MMM. yyyy').format(timeOut.toDate())
                  : 'No time out set';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GatePassDisplay(GatePassId: gatePassId),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Purpose: $purpose",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                "Time In: $formattedTimeIn",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Time Out: $formattedTimeOut",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Flexible(
                            child: Text(
                              gatePassType,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      )
    );
  }
}
