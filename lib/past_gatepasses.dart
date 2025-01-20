import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_gatepass_app/home.dart';

class PastGatePassesPage extends StatefulWidget {
  const PastGatePassesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PastGatePassesPageState createState() => _PastGatePassesPageState();
}

class _PastGatePassesPageState extends State<PastGatePassesPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> expiredGatePasses = [];

  @override
  void initState() {
    super.initState();
    fetchExpiredGatePasses();
  }

  Future<void> fetchExpiredGatePasses() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final expiredGatePassesSnapshot = await FirebaseFirestore.instance
          .collection('users') // Assuming the gate passes are stored under the users collection
          .doc(userId)
          .collection('GatePasses')
          .where('expired', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> gatePasses = [];
      for (var doc in expiredGatePassesSnapshot.docs) {
        gatePasses.add(doc.data());
      }

      setState(() {
        expiredGatePasses = gatePasses;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog("Error fetching expired gate passes: $e");
    }
  }

  String _safeDateTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    }
    return "N/A";
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context,"refresh"),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showGatePassDetails(Map<String, dynamic> gatePass) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GatePassDetailsPage(gatePass: gatePass),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Past Gate Passes',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () {
              Navigator.pop(context,"refresh");
            },
          ),
        ),
        backgroundColor: Colors.white,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : expiredGatePasses.isEmpty
                ? const Center(child: Text("No expired gate passes found."))
                : ListView.builder(
                    itemCount: expiredGatePasses.length,
                    itemBuilder: (context, index) {
                      final gatePass = expiredGatePasses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text("Purpose: ${gatePass['purpose']}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Time In: ${_safeDateTime(gatePass['timeIn'])}"),
                              Text("Time Out: ${_safeDateTime(gatePass['timeOut'])}"),
                            ],
                          ),
                          onTap: () => _showGatePassDetails(gatePass),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class GatePassDetailsPage extends StatefulWidget {
  final Map<String, dynamic> gatePass;

  const GatePassDetailsPage({super.key, required this.gatePass});

  @override
  // ignore: library_private_types_in_public_api
  _GatePassDetailsPageState createState() => _GatePassDetailsPageState();
}

class _GatePassDetailsPageState extends State<GatePassDetailsPage> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      String userId = widget.gatePass['userId'] ?? '';
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          userData = userSnapshot.data();
        });
      }
    } catch (e) {
      _showErrorDialog("Error fetching user data: $e");
    }
  }

  String _safeDateTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    }
    return "N/A";
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 20), // Add space between the label and value
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context,"refresh"),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: (){
            Navigator.pop(context,"refresh");
          }, icon:Icon(Icons.arrow_back)),
          title: Text('Gate Pass Details'),
          backgroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gate Pass Details',
          style: TextStyle(color: Color.fromARGB(255, 8, 7, 8)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow("Name", userData?['name'] ?? "N/A"),
              _buildInfoRow("Roll No.", userData?['rollNo'] ?? "N/A"),
              _buildInfoRow("Purpose", widget.gatePass['purpose'] ?? "N/A"),
              _buildInfoRow("Place", widget.gatePass['place'] ?? "N/A"),
              const SizedBox(height: 20),
              _buildInfoRow("Time In", _safeDateTime(widget.gatePass['timeIn'])),
              _buildInfoRow("Time Out", _safeDateTime(widget.gatePass['timeOut'])),
              const SizedBox(height: 20),
              _buildInfoRow("Real Time In", _safeDateTime(widget.gatePass['realTimeIn'])),
              _buildInfoRow("Real Time Out", _safeDateTime(widget.gatePass['realTimeOut'])),
              _buildInfoRow("Contact No.", userData?['phone'] ?? "N/A"),
              if (widget.gatePass['rejected'] == true) ...[

                const SizedBox(height: 20), // Add spacing before the reject reason
                Text("This Gate Pass was Rejected by Guard at the time of Entry in College.",style: TextStyle(fontSize: 18,color: Colors.red),),
                _buildInfoRow("Reject Reason", widget.gatePass['RejectReasonGuard'] ?? "N/A"),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
