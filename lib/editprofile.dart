import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home.dart';
import 'package:image/image.dart' as img;
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController collegeEmailController = TextEditingController();
  final TextEditingController otpMobileController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController roomNoController = TextEditingController();

  String countryCode = '+91';
  String program = 'Select Program';
  String? semester;
  String branch = 'Select Branch';
  bool mobileVerified = false;
  bool otpRequested = false;
  bool isEditingMobile = false;
  String? _profileImage;  // This holds the file path for the selected image (local path)
  String? _profileImageUrl;  // This holds the Firebase Storage image URL (network image)
  String errorMessage = '';
  String successMessage = '';
  String verificationId = '';
  bool imageExist = false ;
  int profileCompletionStatus = 0;
  final List<String> branches = [
  'Select Branch',
  'Computer Science & Engineering',
    'Information Technology',
    'Computer Science & Design',
    'Integrated Dual Degree (CSE+AI)',
    'Mathematics & Computing',
    'Electronics Engineering',
    'Electronics Engineering Major in E-Vehicle',
    'Petroleum Engineering',
    'Integrated Dual Degree (Petroleum)',
    'Chemical Engineering',
    'Renewable Energy Engineering',
    'Petrochemical & Polymers Engineering',
    'Mechanical Engineering'

];

  final Map<String, List<String>> semesters = {
    'Select Program': ['Semester 1'],
    'B.Tech': List.generate(8, (index) => 'Semester ${index + 1}'),
    'MBA': List.generate(6, (index) => 'Semester ${index + 1}'),
    'PhD': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }


  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;

      // If a profilePic is stored in the database, initialize it
      if (userData != null && userData['profilePic'] != null) {
        setState(() {
          _profileImageUrl = userData['profilePic']; // Set the profile pic URL
          imageExist=true;
        });
      }

      setState(() {
        nameController.text =
            userData?['name'] ?? user.displayName ?? 'No Name';
        collegeEmailController.text =
            userData?['email'] ?? user.email ?? 'No Email';
        phoneController.text = userData?['phone'] ?? '';
        rollNoController.text = userData?['rollNo'];
        roomNoController.text = userData?['roomNo'] ?? ''; // Set room number
        branch = userData?['branch'] ?? 'Select Branch';
        program = userData?['program'] ?? 'Select Program';
        semester = userData?['semester'] ??
            (program == 'PhD' ? null : 'Semester 1');
      });
    }
  }

  Future<void> _requestOTP() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '$countryCode${phoneController.text}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await user.updatePhoneNumber(credential);
          setState(() {
            mobileVerified = true;
            otpRequested = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            errorMessage = e.message ?? 'Unknown error occurred';
            otpRequested = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            otpRequested = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    }
  }

  Future<void> _validateMobileOTP() async {
    String otp = otpMobileController.text;
    if (otp.length == 6) {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: otp);

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePhoneNumber(credential);
        setState(() {
          mobileVerified = true; // Set this flag locally
          otpRequested = false;
          errorMessage = '';
        });
      }
    } else {
      setState(() {
        errorMessage = 'Invalid OTP';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => errorMessage = ''),
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileImage(),
                const SizedBox(height: 20),
                _buildNonEditableField('Name', nameController),
                const SizedBox(height: 10),
                _buildNonEditableField('Roll No.', rollNoController),
                const SizedBox(height: 10),
                _buildEditableField(
                    'Room No.', roomNoController), // Room number input field
                const SizedBox(height: 10),
                _buildDropdown(
                  'Program',
                  program,
                  ['Select Program', 'B.Tech', 'MBA', 'PhD'],
                  (newProgram) => setState(() {
                    program = newProgram ?? 'Select Program';
                    semester = semesters[program]?.isNotEmpty == true
                        ? semesters[program]![0]
                        : null;
                  }),
                  isEnabled: program != 'B.Tech', // Disable the dropdown if B.Tech is selected
                ),
                const SizedBox(height: 10),
                if (program != 'PhD')
                  _buildDropdown(
                    'Semester',
                    semester ?? 'Semester 1',
                    semesters[program]!,
                    (newSemester) => setState(() => semester = newSemester),
                  ),
                const SizedBox(height: 10),
                _buildDropdown(
                  'Branch',
                  branch,
                  branches,
                  (newBranch) =>
                      setState(() => branch = newBranch ?? 'Select Branch'),
                       isEnabled: program != 'B.Tech', // Disable the dropdown if B.Tech is selected
                ),
                const SizedBox(height: 10),
                _buildNonEditableField('College Email', collegeEmailController),
                const SizedBox(height: 10),
                _buildMobileField(),
                const SizedBox(height: 20),
                if (errorMessage.isNotEmpty)
                  _buildMessage(errorMessage, Colors.red),
                if (successMessage.isNotEmpty)
                  _buildMessage(successMessage, Colors.green),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfileAndGoHome,
                  child: const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight, // Better placement for edit icon
        children: [
          // Profile image container
          Container(
            width: 120.0,
            height: 160.0,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle, // Square shape
              image: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(_profileImageUrl!),  // Use the URL directly
                fit: BoxFit.cover,
              )
                  : const DecorationImage(
                image: AssetImage('assets/profile_pic.jpg'), // Default local image
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(10.0), // Rounded corners
            ),
          ),
          // Edit icon button
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: Colors.white, // Background color for the edit button
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.blue,
                size: 20.0,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEditableField(
      String labelText, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration:
          InputDecoration(labelText: labelText, border: OutlineInputBorder()),
    );
  }

  Widget _buildNonEditableField(
      String labelText, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration:
          InputDecoration(labelText: labelText, border: OutlineInputBorder()),
    );
  }

  Widget _buildMobileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DropdownButton<String>(
              value: countryCode,
              items: ['+91', '+1', '+44', '+61', '+81']
                  .map((code) =>
                      DropdownMenuItem(value: code, child: Text(code)))
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => countryCode = newValue ?? '+91'),
            ),
            const SizedBox(width: 10),
            Expanded(child: _buildMobileNumberField()),
            if (!mobileVerified && !otpRequested)
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _requestOTP,
              ),
            if (mobileVerified)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        mobileVerified = false;
                        otpRequested = false;
                      });
                    },
                    child: const Text('Change Mobile No.'),
                  ),
                ],
              ),
          ],
        ),
        if (!mobileVerified && otpRequested) _buildOTPSection(), // OTP section
      ],
    );
  }

  Widget _buildMobileNumberField() {
    return TextField(
      controller: phoneController,
      keyboardType: TextInputType.number,
      maxLength: 10,
      readOnly: mobileVerified || otpRequested,
      decoration: const InputDecoration(
        labelText: 'Mobile Number',
        border: OutlineInputBorder(),
        counterText: '',
      ),
    );
  }

  Widget _buildOTPSection() {
    return Column(
      children: [
        TextField(
          controller: otpMobileController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Enter OTP',
            border: OutlineInputBorder(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _requestOTP,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Resend OTP',
                  style: TextStyle(color: Color.fromARGB(255, 68, 17, 135))),
            ),
            ElevatedButton(
              onPressed: _validateMobileOTP,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Validate OTP'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown(
  String labelText,
  String currentValue,
  List<String> items,
  void Function(String?) onChanged,
  {bool isEnabled = true} // Optional parameter to control if the dropdown is editable
) {
  return InputDecorator(
    decoration: InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: currentValue,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(color: isEnabled ? Colors.black : Colors.black), // Force text color to black
                  ),
                ))
            .toList(),
        onChanged: isEnabled ? onChanged : null, // Disable if not editable
        style: TextStyle(
          color: isEnabled ? Colors.black : Colors.black, // Set color regardless of the state
        ),
      ),
    ),
  );
}


  Widget _buildMessage(String message, Color color) {
    return Text(
      message,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  void _saveProfileAndGoHome() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (imageExist &&
      nameController.text.isNotEmpty &&
          phoneController.text.isNotEmpty &&
          collegeEmailController.text.isNotEmpty &&
          program != 'Select Program' &&
          branch != 'Select Branch') {
        // Get current phone number from Firestore
        var userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String currentPhone = userData['phone'] ?? '';

        // Check if the mobile number is the same as the one in the database
        if ((currentPhone == phoneController.text) ||
            (currentPhone == '' && mobileVerified)) {
          // If the phone number is the same, save the profile
          profileCompletionStatus = 1; // Profile complete
          await _updateProfile(user.uid);
        } else {
          // If the phone number is different, verify the OTP first
          if (mobileVerified) {
            profileCompletionStatus = 1; // Profile complete
            await _updateProfile(user.uid);
          } else {
            setState(() {    
              errorMessage = 'Please verify your mobile number before saving';
            });
          }
        }

        
      } else {
        setState(() => errorMessage = 'Please complete all required fields correctly.');
      }
    }
  }

  Future<void> _updateProfile(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': nameController.text,
        'phone': phoneController.text,
        'rollNo': rollNoController.text,
        'roomNo': roomNoController.text,
        'branch': branch,
        'program': program,
        'semester': semester,
        'profileCompletionStatus': profileCompletionStatus,
      });

      setState(() {
        successMessage = 'Profile updated successfully!';
      });
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );

    } catch (e) {
      setState(() {
        errorMessage = 'Failed to update profile: $e';
      });
    }
  }


  Future<void> _pickImage() async {
    // Pick an image from the gallery
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Set the selected image path (using String?) instead of File
      setState(() {
        imageExist = true ;
        _profileImage = pickedFile.path; // Store the file path as String?
      });

      // Upload the image to Firebase Storage and get the download URL
      String? downloadUrl = await _uploadProfileImage(_profileImage!);

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        // Update the user's profilePic field in Firestore with the download URL
        await _updateProfilePicInFirestore(downloadUrl);
        imageExist = true ;
        // Save the Firebase download URL for later display
        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    }
  }

  Future<String?> _uploadProfileImage(String imagePath) async {
    User? user = FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();

    final userData = userDoc.data() as Map<String, dynamic>?;

    try {
      // Define the storage path for the image
      String storagePath = "Students' Profile Pics/${userData?['rollNo']}.jpg";

      // Reference to Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference storageReference = storage.ref().child(storagePath);

      // Upload the file to Firebase Storage
      UploadTask uploadTask = storageReference.putFile(File(imagePath)); // Convert path to File
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get the image URL after upload
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return ''; // Return an empty string in case of an error
    }
  }

  Future<void> _updateProfilePicInFirestore(String downloadUrl) async {
    User? user = FirebaseAuth.instance.currentUser;

    try {
      // Reference to Firestore 'users' collection
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Update the profilePic field in Firestore with the download URL
      await firestore.collection('users').doc(user?.uid).update({
        'profilePic': downloadUrl,  // Store the URL as a reference
      });

      print("Profile picture updated successfully.");
    } catch (e) {
      print("Error updating Firestore: $e");
    }
  }
}
