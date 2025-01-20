// ignore_for_file: avoid_print, library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'package:uuid/uuid.dart';
class VacationGatePassPage extends StatefulWidget {
  const VacationGatePassPage({super.key});

  @override
  _VacationGatePassPageState createState() => _VacationGatePassPageState();
}

class _VacationGatePassPageState extends State<VacationGatePassPage> {
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _roomNoController = TextEditingController();
  final _programController = TextEditingController();
  final _branchController = TextEditingController();
  final _semesterController = TextEditingController();
  final _purposeController = TextEditingController();
  final _placeController = TextEditingController();
  final _overnightStayController = TextEditingController();
  final _contactController = TextEditingController();
  // ignore: non_constant_identifier_names
  String? USERID ;
  String gatepassid = '';
  DateTime? _dateOut;
  DateTime? _dateIn;
  TimeOfDay? _timeOut;
  TimeOfDay? _timeIn;

  final _formKey = GlobalKey<FormState>(); // Form key for validation

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the page loads
  }


  Future<void> _fetchUserData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    USERID = userId;

    try {
      // Fetch data from Firestore (assuming a 'users' collection)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Assuming fields in Firestore document
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = userData['name'] ?? '';
          _rollNoController.text = userData['rollNo'] ?? '';
          _roomNoController.text = userData['roomNo'] ?? '';
          _programController.text = userData['program'] ?? '';
          _branchController.text = userData['branch'] ?? '';
          _semesterController.text = userData['semester'] ?? '';
          _contactController.text = userData['phone'] ?? '';
          // Set other fields similarly
        });
      } else {
        print("No user data found");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }
  Future<void> _selectDate(BuildContext context, bool isOutDate) async {
    DateTime initialDate = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isOutDate ? initialDate : (_dateOut ?? initialDate),
      firstDate: isOutDate ? initialDate : (_dateOut ?? initialDate), // Restrict Date In to be after Date Out
      lastDate: DateTime(2101),
    );

    setState(() {
      if (picked != null) {
        if (isOutDate) {
          _dateOut = picked;
          _dateIn = null; // Reset Date In if Date Out changes
          _timeIn = null;
        } else {
          _dateIn = picked;
        }
      }
    });
  }


  Future<void> _selectTime(BuildContext context, bool isOutTime) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        DateTime now = DateTime.now();
        DateTime selectedDateTime;

        if (isOutTime) {
          if (_dateOut != null) {
            selectedDateTime = DateTime(
              _dateOut!.year,
              _dateOut!.month,
              _dateOut!.day,
              picked.hour,
              picked.minute,
            );

            if (selectedDateTime.isAfter(now)) {
              _timeOut = picked;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Time Out cannot be in the past.")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select Date Out first.")),
            );
          }
        } else {
          if (_dateIn != null && _dateOut != null && _timeOut != null) {
            DateTime dateTimeOut = DateTime(
              _dateOut!.year,
              _dateOut!.month,
              _dateOut!.day,
              _timeOut!.hour,
              _timeOut!.minute,
            );

            selectedDateTime = DateTime(
              _dateIn!.year,
              _dateIn!.month,
              _dateIn!.day,
              picked.hour,
              picked.minute,
            );

            if (selectedDateTime.isAfter(dateTimeOut)) {
              _timeIn = picked;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Time In cannot be before Time Out.")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Please select Date and Time Out first.")),
            );
          }
        }
      });
    }
  }



  Future<void> generateGatePass(
      String? userId, String gatepassid, DateTime timeIn, DateTime timeOut) async {
    int outStatus = 0;
    int inStatus = 0;
    bool expiredStatus = false;

    // Add gatepassType and request here
    String gatepassType = "VACATION"; // Example value, can be dynamic
    int wardenApproval = 0; // Indicates pending by default

    // Fetch user's branch to determine the appropriate HOD approval field
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    String branch = userSnapshot['branch'];

    if (!userSnapshot.exists) {
      print("User not found");
      return;
    }



    Map<String, dynamic> gatePassData = {
      'userId': userId,
      'UniqueId': gatepassid,  // Save gatepassid here
      'studentBranch':branch,
      'out': outStatus,
      'in': inStatus,
      'expired': expiredStatus,
      'timeIn': timeIn,
      'timeOut': timeOut,
      'request':0,
      'purpose': _purposeController.text,
      'place': _placeController.text,
      'overnightStayInfo': _overnightStayController.text,
      'gatepassType': gatepassType,
      'wardenApproval': wardenApproval,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('GatePasses')
        .add(gatePassData);
  }




  void _generateGatePass() {
    if (_formKey.currentState!.validate() &&
        _dateOut != null &&
        _timeOut != null &&
        _dateIn != null &&
        _timeIn != null) {

      // Generate unique gatepassid here
      gatepassid = Uuid().v4();

      DateTime timeOut = DateTime(
        _dateOut!.year,
        _dateOut!.month,
        _dateOut!.day,
        _timeOut!.hour,
        _timeOut!.minute,
      );

      DateTime timeIn = DateTime(
        _dateIn!.year,
        _dateIn!.month,
        _dateIn!.day,
        _timeIn!.hour,
        _timeIn!.minute,
      );

      // Save gate pass data with generated gatepassid
      generateGatePass(USERID, gatepassid, timeIn, timeOut);

      _showGatePassDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields and select Date & Time.")),
      );
    }
  }

  void _showGatePassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Gate Pass Request Sent!'),
          content: Text(
            'Your gate pass request has been sent. After approval, You can access them from "Saved Gate Passes".',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context)=>HomePage())); // Redirect to home page
              },
              child: Text('Okay'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.pop(context,"refresh");
        }, icon:Icon(Icons.arrow_back)),
        title: const Text("Gate Pass Generation"),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              const Center(
                child: Text(
                  'VACATION GATE PASS',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField("Name:", _nameController, isEditable: false),
              _buildTextField("Roll No.:", _rollNoController,
                  isEditable: false),
              _buildTextField("Room No.:", _roomNoController,
                  isEditable: false),
              _buildTextField("Program:", _programController,
                  isEditable: false),
              _buildTextField("Branch:",_branchController,isEditable: false),
              _buildTextField("Semester:", _semesterController,
                  isEditable: false),
              _buildTextField("Contact No.:", _contactController,
                  isEditable: false),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeField(
                      label: "Date Out:",
                      displayText: _dateOut != null
                          ? "${_dateOut!.day}-${_dateOut!.month}-${_dateOut!.year}"
                          : "Select Date",
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDateTimeField(
                      label: "Time Out:",
                      displayText: _timeOut != null
                          ? _timeOut!.format(context)
                          : "Select Time",
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeField(
                      label: "Date In:",
                      displayText: _dateIn != null
                          ? "${_dateIn!.day}-${_dateIn!.month}-${_dateIn!.year}"
                          : "Select Date",
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDateTimeField(
                      label: "Time In:",
                      displayText: _timeIn != null
                          ? _timeIn!.format(context)
                          : "Select Time",
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              _buildTextField("Purpose:", _purposeController),
              _buildTextField("Place:", _placeController),
              _buildTextField("Overnight Stay Info:", _overnightStayController),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () {
                  _generateGatePass();
                },
                child: const Text("Request Gate Pass"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: isEditable,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String displayText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              displayText,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _roomNoController.dispose();
    _programController.dispose();
    _branchController.dispose();
    _semesterController.dispose();
    _purposeController.dispose();
    _placeController.dispose();
    _overnightStayController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}

void main() {
  runApp(const MaterialApp(
    home: VacationGatePassPage(),
  ));
}
