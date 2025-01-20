// ignore_for_file: avoid_print, library_private_types_in_public_api, unnecessary_null_comparison

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gatepass_display.dart';
import 'package:uuid/uuid.dart';

class LocalGatePassPage extends StatefulWidget {
  const LocalGatePassPage({super.key});

  @override
  _LocalGatePassPageState createState() => _LocalGatePassPageState();
}

class _LocalGatePassPageState extends State<LocalGatePassPage> {
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
  String ? USERID ;
  String gatepassid = '';
  final DateTime _dateOut = DateTime.now(); // Set Date Out to current date and make it non-editable
final DateTime _dateIn = DateTime.now(); 
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
    USERID = userId ;

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
            _dateOut.year,
            _dateOut.month,
            _dateOut.day,
            picked.hour,
            picked.minute,
          );

          if (selectedDateTime.isAfter(now)) {
            // Validate that Time Out is not after 8:30 PM
            if (picked.hour > 20 || (picked.hour == 20 && picked.minute > 30)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Time Out cannot be after 8:30 PM.")),
              );
              return; // Exit the method if the time is invalid
            }

            _timeOut = picked;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Time Out cannot be in the past.")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select Date Out first.")),
          );
        }
      } else {
        if (_dateIn != null && _dateOut != null && _timeOut != null) {
          selectedDateTime = DateTime(
            _dateIn.year,
            _dateIn.month,
            _dateIn.day,
            picked.hour,
            picked.minute,
          );

          // Validate that Time In is not after 8:30 PM
          if (picked.hour > 20 || (picked.hour == 20 && picked.minute > 30)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Time In cannot be after 8:30 PM.")),
            );
            return; // Exit the method if the time is invalid
          }

          if (_timeOut != null) {
            selectedDateTime = DateTime(
              _dateIn.year,
              _dateIn.month,
              _dateIn.day,
              picked.hour,
              picked.minute,
            );

            DateTime timeOutDateTime = DateTime(
              _dateOut.year,
              _dateOut.month,
              _dateOut.day,
              _timeOut!.hour,
              _timeOut!.minute,
            );

            if (selectedDateTime.isAfter(timeOutDateTime)) {
              // Ensure Time In is within 3 hours of Time Out
              final difference = selectedDateTime.difference(timeOutDateTime).inHours;
              if (difference <= 2) {
                _timeIn = picked;
              } else {
                _timeIn=null;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Time In cannot be more than 3 hours after Time Out.")),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Time In cannot be before Time Out.")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select Time Out first.")),
            );
          }
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
  String gatepassType = "LOCAL"; // Example value, can be dynamic

  Map<String, dynamic> gatePassData = {
    'userId': USERID,
    'UniqueId': gatepassid,  // Save gatepassid here
    'out': outStatus,
    'in': inStatus,
    'expired': expiredStatus,
    'timeIn': timeIn,
    'timeOut': timeOut,
    'purpose': _purposeController.text,
    'place': _placeController.text,
    'overnightStayInfo': _overnightStayController.text,
    'gatepassType': gatepassType,  // New variable
  };

  await FirebaseFirestore.instance
      .collection('users')
      .doc(USERID)
      .collection('GatePasses')
      .add(gatePassData);

  print("Gate pass with ID $gatepassid generated and saved successfully!");
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
      _dateOut.year,
      _dateOut.month,
      _dateOut.day,
      _timeOut!.hour,
      _timeOut!.minute,
    );

    DateTime timeIn = DateTime(
      _dateIn.year,
      _dateIn.month,
      _dateIn.day,
      _timeIn!.hour,
      _timeIn!.minute,
    );

    // Save gate pass data with generated gatepassid
    generateGatePass(USERID, gatepassid, timeIn, timeOut);

    // Navigate to GatePassDisplay with gatepassid
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GatePassDisplay(GatePassId: gatepassid),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all required fields and select Date & Time.")),
    );
  }
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
          padding: const EdgeInsets.all(4.0),
          child: ListView(
            children: [
              const Center(
                child: Text(
                  'LOCAL GATE PASS',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
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
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildDateTimeField(
                      label: "Date Out:",
                      displayText: "${_dateIn.day}-${_dateIn.month}-${_dateIn.year}",
                      onTap: () {}, // Date is fixed, no need for onTap action
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildTimeField(
                      label: "Time Out:",
                      time: _timeOut,
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildDateTimeField(
                      label: "Date In:",
                      displayText: "${_dateIn.day}-${_dateIn.month}-${_dateIn.year}",
                      onTap: () {}, // Date is fixed, no need for onTap action
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildTimeField(
                      label: "Time In:",
                      time: _timeIn,
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildTextField("Purpose:", _purposeController),
              _buildTextField("Place:", _placeController),
              _buildTextField("Overnight Stay Info:", _overnightStayController),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: _generateGatePass,
                child: const Text("Generate Gate Pass"),
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
  required String label,  // Dynamic label
  required String displayText,
  required void Function() onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(displayText),
        ],
      ),
    ),
  );
}

Widget _buildTimeField({
  required String label,  // Dynamic label
  required TimeOfDay? time,
  required void Function() onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(time != null ? time.format(context) : 'Select Time'),
        ],
      ),
    ),
  );
}
}